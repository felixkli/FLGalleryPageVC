//
//  FLGalleryPageVC.swift
//  hypebeast
//
//  Created by Felix Li on 31/7/15.
//

import Foundation
import SDWebImage

public protocol FLGalleryDataSource: AnyObject {
    func gallery(galleryVC: FLGalleryPageVC, placeholderImageForIndex index: Int) -> UIImage?
}

// OPTIONAL
public extension FLGalleryDataSource {
    func gallery(galleryVC: FLGalleryPageVC, placeholderImageForIndex index: Int) -> UIImage? { return nil }
}

public protocol FLGalleryDelegate: AnyObject {
    func gallery(galleryVC: FLGalleryPageVC, shareButtonPressedFor currentIndex: Int)
    func gallery(galleryVC: FLGalleryPageVC, didShareActivity activityType: UIActivity.ActivityType?, currentIndex: Int)
}


// OPTIONAL
public extension FLGalleryDelegate {
    
    func gallery(galleryVC: FLGalleryPageVC, shareButtonPressedFor currentIndex: Int) { }
    func gallery(galleryVC: FLGalleryPageVC, didShareActivity activityType: UIActivity.ActivityType?, currentIndex: Int) { }
}

public class FLGalleryPageVC: UIViewController {
    
    public override var modalPresentationStyle: UIModalPresentationStyle {
        get { return .fullScreen }
        set {
            print("[gallery] modalPresentationStyle will always return fullscreen, cannot set")
        }
    }

    // Controllers
    public var pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    // Gesture
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    // Delegate
    public weak var delegate: FLGalleryDelegate?
    public weak var dataSource: FLGalleryDataSource?
    
    // Views
    private let pageControl =  UIPageControl()
    private let buttonContainer = UIView()
    private let exitButton = UIButton(type: .custom)
    private let shareButton = UIButton(type: .custom)
    
    // Constants
    private let exitButtonSize: CGFloat = 28
    private let exitButtonPad: CGFloat = 10
    private let barButtonSpacing: CGFloat = 15
    private let barButtonHorizontalPadding: CGFloat = 8
    private let barButtonVerticalPadding: CGFloat = 8
    public var pageControlPadding: CGFloat = 16
    private var statusBarHidden = false
    
    // Variables
    public var useCustomShare: Bool = false
    
    public var itemName: String?
    public var shareLink: String?
    
    // Options
    public var backgroundColor: UIColor = UIColor.white {
        didSet {
            UIView.animate(withDuration: .default) {
                self.view.backgroundColor = self.backgroundColor
            }
        }
    }
    
    public var buttonColors: UIColor = UIColor.black {
        didSet {
            
            UIView.animate(withDuration: .default) {
                self.exitButton.tintColor = self.buttonColors
                self.shareButton.tintColor = self.buttonColors
            }
        }
    }
    
    public fileprivate(set) var currentPage = 0 {
        didSet {
            updatePageControl()
        }
    }
    
    public fileprivate(set) var originalPage = 0
    
    public var imageLinks: [String] = [] {
        didSet {
            updatePageControl()
        }
    }
    
    public var pageControlpageIndicatorTintColor = UIColor(white: 0.9, alpha: 0.8) {
        didSet {
            updatePageControl()
        }
    }
    public var pageControlCurrentPageIndicatorTintColor = UIColor(white: 0.2, alpha: 0.8) {
        didSet {
            updatePageControl()
        }
    }
    
    public var enablePageControl = false {
        didSet {
            pageControl.isHidden = !enablePageControl
        }
    }
    
    public var tapToClose: Bool = false {
        didSet {
            updateGesture()
        }
    }
    
    public var customActivities: [UIActivity] = []
    
    // Hide bottom bar
    public override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set {}
    }
    
    public var imageOffset = CGPoint(x: 0, y: 0) {
        didSet {
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    public var enableInfiniteScroll: Bool = false
    
    public init(currentIndex: Int, links: [String], placeholder: UIImage? = nil, startingFrame: CGRect? = nil) {
        
        super.init(nibName: nil, bundle: nil)
        
        modalTransitionStyle = .crossDissolve
        
        itemName = title
        currentPage = currentIndex
        imageLinks = links
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        modalPresentationCapturesStatusBarAppearance = true
        
        view.backgroundColor = backgroundColor
        
        let exitImage = UIImage(named: "close-icon", in: Bundle(for: FLGalleryPageVC.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        
        exitButton.setImage(exitImage, for: .normal)
        exitButton.tintColor = .black
        exitButton.setTitle("", for: .normal)
        exitButton.addTarget(self, action: #selector(FLGalleryPageVC.donePressed), for: .touchUpInside)
        
        let shareImage = UIImage(named: "share-icon", in: Bundle(for: FLGalleryPageVC.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        
        shareButton.setImage(shareImage, for: .normal)
        shareButton.tintColor = .black
        shareButton.setTitle("", for: .normal)
        shareButton.addTarget(self, action: #selector(FLGalleryPageVC.sharePressed), for: .touchUpInside)
                
        buttonContainer.backgroundColor = UIColor(white: 1, alpha: 0.2)
        buttonContainer.layer.cornerRadius = 5
        
        pageControl.backgroundColor = UIColor(white: 1, alpha: 0.2)
        pageControl.pageIndicatorTintColor = .init(hex: "#F2F1F0")
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.layer.cornerRadius = 5
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        pageControl.backgroundStyle = .minimal
        pageControl.allowsContinuousInteraction = false
        
        setupPageViewController()
        updatePageControl()
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gesturePanned(sender:)))
        panGestureRecognizer?.maximumNumberOfTouches = 1
        pageVC.view.addGestureRecognizer(panGestureRecognizer!)
        
        view.addSubview(pageControl)
        view.addSubview(buttonContainer)
        
        buttonContainer.addSubview(exitButton)
        buttonContainer.addSubview(shareButton)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.statusBarHidden = true

        UIView.animate(withDuration: .default) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.statusBarHidden = false
        
        UIView.animate(withDuration: .default) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        if #available(iOS 11.0, *), self.view.safeAreaInsets.top > 0 {
            return .fade
        }
        
        return .slide
    }
    
    public override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var topPadding: CGFloat = 0
        if #available(iOS 11.0, *) {
            let safeAreaHeight = self.view.safeAreaInsets.top
            topPadding += safeAreaHeight
        }
        
        if let _ = shareLink {
            shareButton.alpha = 1
                        
            buttonContainer.frame = CGRect(x: view.bounds.width - (exitButtonSize) * 2 - exitButtonPad - barButtonSpacing - barButtonHorizontalPadding * 2,
                                           y: topPadding,
                                           width: exitButtonSize * 2 + barButtonSpacing + barButtonHorizontalPadding * 2,
                                           height: exitButtonSize + barButtonVerticalPadding * 2)
            exitButton.frame = CGRect(x: exitButtonSize + barButtonSpacing + barButtonHorizontalPadding, y: barButtonVerticalPadding, width: exitButtonSize, height: exitButtonSize)
            shareButton.frame = CGRect(x: barButtonHorizontalPadding, y: barButtonVerticalPadding, width: exitButtonSize, height: exitButtonSize)
            
        } else {
            shareButton.alpha = 0
            
            buttonContainer.frame = CGRect(x: view.bounds.width - (exitButtonSize) - exitButtonPad - barButtonSpacing, y: topPadding, width: exitButtonSize + barButtonSpacing, height: exitButtonSize)
            exitButton.frame = CGRect(x: 0, y: 0, width: exitButtonSize, height: exitButtonSize)
            shareButton.frame = CGRect.zero
        }
        
        if !self.isBeingDismissed {
            pageVC.view.frame = view.bounds
        }
        
        pageControl.sizeToFit()
        let pageControlWidth = pageControl.frame.size.width + (pageControlPadding * 2)
        pageControl.frame = CGRect(x: (view.bounds.width - pageControlWidth) / 2.0, y: view.bounds.height - 50, width: pageControlWidth, height: 20)
    }
    
    public func isModal() -> Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }
    
    public func setCurrentImagePage(page: Int) {
        currentPage = page
        originalPage = page
        
        updatePageControl()
        
        let vc = self.viewControllerForIndex(index: self.currentPage)
        self.pageVC.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
    }
    
    public func imageFrame(forPage page: Int) -> CGRect{
        if self.modalPresentationStyle == .fullScreen {
            
            if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows,
               let first = window.first {
                self.view.frame = first.bounds
            }
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
        var rect = view.bounds
        
        var galleryPageVC: FLGalleryImageVC?
        
        if page == currentPage,
            let vc = self.pageVC.viewControllers?.first as? FLGalleryImageVC {
            
            galleryPageVC = vc
                        
        } else if let vc = self.viewControllerForIndex(index: self.currentPage) as? FLGalleryImageVC {
            
            galleryPageVC = vc
        }
        
        if let vc = galleryPageVC {
            
            vc.view.frame = self.view.frame
            vc.view.layoutIfNeeded()
            rect = CGRect(x: vc.scrollViewContentInset.left, y: vc.scrollViewContentInset.top, width: vc.imageView.frame.width, height: vc.imageView.frame.height)
        }
        
        return rect
    }
    
    public func imageView(forPage page: Int) -> UIView {
        if page == currentPage,
            let vc = self.pageVC.viewControllers?.first as? FLGalleryImageVC {
            
            vc.view.layoutIfNeeded()
            return vc.imageView
            
        } else if let vc = self.viewControllerForIndex(index: self.currentPage) as? FLGalleryImageVC {
            
            vc.view.layoutIfNeeded()
            return vc.imageView
        }
        
        return self.view
    }
    
    private func updatePageControl() {
        pageControl.numberOfPages = imageLinks.count
        pageControl.currentPage = currentPage
        pageControl.pageIndicatorTintColor = self.pageControlpageIndicatorTintColor
        pageControl.currentPageIndicatorTintColor = self.pageControlCurrentPageIndicatorTintColor
    }
    
    private func setupPageViewController() {
        pageVC.view.backgroundColor = UIColor.clear
        pageVC.delegate = self
        pageVC.dataSource = self
        
        // Unable to use addChild, FLGalleryImageVC didlayoutsubview called when being dismissed, sets the image and scrollView to original image size before transition
        self.view.addSubview(pageVC.view)
        //        self.addChild(child: pageVC, to: view)
    }
    
    fileprivate func viewControllerForIndex(index: Int) -> UIViewController {
        
        let galleryImageVC = FLGalleryImageVC(index: index, imageURL: imageLinks[index])
        
        galleryImageVC.placeHolderImage = self.dataSource?.gallery(galleryVC: self, placeholderImageForIndex: index)
        galleryImageVC.imageOffset = self.imageOffset
        
        self.updateGesture()
        
        return galleryImageVC
    }
    
    func updateGesture() {
        guard let viewControllers = self.pageVC.viewControllers,
              tapToClose,
              viewControllers.count > self.currentPage
                
        else { return
        }
        
        if let vc = viewControllers[self.currentPage] as? FLGalleryImageVC {
            vc.setupSingleTap(target: self, action: #selector(FLGalleryPageVC.donePressed(sender:)))
        }
    }
    
    @objc func gesturePanned(sender: UIGestureRecognizer) {
        guard let panGesture = sender as? UIPanGestureRecognizer else { return }
        
        let translation = panGesture.translation(in: pageVC.view)
        
        switch panGesture.state {
        case .changed:  self.pageVC.view.frame.origin = translation
        case .ended:
            if abs(translation.y) / self.pageVC.view.bounds.height > 0.20 {
                self.dismiss(animated: true, completion: nil)
            }else{
                UIView.animate(withDuration: .default, animations: {
                    self.pageVC.view.frame.origin = CGPoint(x: 0, y: 0)
                    self.view.alpha = 1
                })
            }
        default: break
        }
    }
    
    @objc public func donePressed(sender: UITapGestureRecognizer? = nil) {
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc public func sharePressed(sender: Any? = nil) {
        guard
            imageLinks.count > 0,
            let imageURL = URL(string: imageLinks[currentPage])
            
            else{ return
        }
        
        if useCustomShare {
            self.delegate?.gallery(galleryVC: self, shareButtonPressedFor: currentPage)
        }else{
            SDWebImage.SDWebImageManager.shared.loadImage(with: imageURL, options: [], progress: nil, completed: { (image, _, error, cacheType, complete, url) in
                
                if complete == true {
                    
                    var activityItems:[Any] = [] //[card, PostItemProvider(card: card)]
                    
                    if let shareLink = self.shareLink,
                        let shareURL = URL(string: shareLink) {
                        
                        activityItems.append(shareURL)
                    }
                    
                    if let image = image {
                        activityItems.append(image)
                    }
                    
                    activityItems.append(self.itemName ?? "")
                    
                    let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: self.customActivities)
                    
                    vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print, UIActivity.ActivityType.saveToCameraRoll, UIActivity.ActivityType.message, UIActivity.ActivityType.mail]
                    
                    // For iPad Popover Controller
                    if let popoverController = vc.popoverPresentationController {
                        
                        switch sender {
                        case let sender as UIBarButtonItem:
                            popoverController.barButtonItem = sender
                        case let sender as UIGestureRecognizer:
                            popoverController.sourceView = sender.view
                        case let sender as UIButton:
                            popoverController.sourceView = sender
                        default: break
                        }
                    }
                    
                    self.present(vc, animated: true, completion: nil)
                    
                    vc.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
                        self.delegate?.gallery(galleryVC: self, didShareActivity: activityType, currentIndex: self.currentPage)
                    }
                }
            })
        }
    }
    
    public override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: UIPageViewControllerDataSource
extension FLGalleryPageVC: UIPageViewControllerDataSource{
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if (currentPage == 0) {
            return enableInfiniteScroll
            ? self.viewControllerForIndex(index: self.imageLinks.count - 1)
            : nil
        }else{
            return self.viewControllerForIndex(index: currentPage - 1)
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if (currentPage == imageLinks.count - 1) {
            return enableInfiniteScroll
            ? self.viewControllerForIndex(index: 0)
            : nil
        }else{
            return self.viewControllerForIndex(index: currentPage + 1)
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let vc = pageViewController.viewControllers!.first as? FLGalleryImageVC {
            if let index = vc.index,
                index != currentPage {
                self.currentPage = index
            }
        }
    }
}

// MARK: UIPageViewControllerDelegate
extension FLGalleryPageVC: UIPageViewControllerDelegate{
    
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        if let vc = pendingViewControllers.first as? FLGalleryImageVC {
            if let index = vc.index,
                index != currentPage{
                self.currentPage = index
            }
        }
        
        print("[Transition] self.currentPage: \(self.currentPage)")
    }
}

fileprivate extension UIViewController {
    
    func addChild(child: UIViewController?, to view: UIView? = nil) {
        
        guard
            let child = child,
            let baseView = (view ?? self.view)
        else {
            print("[UIViewController] Unable to add child View Controller")
            return
        }
        
        addChild(child)
        baseView.addSubview(child.view)
        child.didMove(toParent: self)
    }
}

fileprivate extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        
        var hexString = hex
        if hexString.first == "#" {
            hexString.removeFirst()
        }
        
        let scanner = Scanner(string: hexString)
        scanner.currentIndex = scanner.string.startIndex
        
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: alpha
        )
    }
}

fileprivate extension TimeInterval {
    static let `default`: TimeInterval = 0.3
}
