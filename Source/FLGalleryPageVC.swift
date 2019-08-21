//
//  FLGalleryPageVC.swift
//  hypebeast
//
//  Created by Felix Li on 31/7/15.
//

import Foundation
import SDWebImage

public protocol FLGalleryDataSource: class {
    
    func gallery(galleryVC: FLGalleryPageVC, placeholderImageForIndex index: Int) -> UIImage?
}

// OPTIONAL
public extension FLGalleryDataSource {
    
    func gallery(galleryVC: FLGalleryPageVC, placeholderImageForIndex index: Int) -> UIImage? { return nil }
}

public protocol FLGalleryDelegate: class {
    
    func gallery(galleryVC: FLGalleryPageVC, didShareActivity activityType: UIActivity.ActivityType?, currentIndex: Int)
}


// OPTIONAL
public extension FLGalleryDelegate {
    
    func gallery(galleryVC: FLGalleryPageVC, didShareActivity activityType: UIActivity.ActivityType?, currentIndex: Int) { }
}

public class FLGalleryPageVC: UIViewController {
    
    // Controllers
    
    public var pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    // Gesture
    
    var panGestureRecognizer: UIPanGestureRecognizer?
    
    // Delegate
    
    public weak var delegate: FLGalleryDelegate?
    public weak var dataSource: FLGalleryDataSource?
    
    // Views
    
    private let pageControl =  UIPageControl()
    
    private let buttonContainer = UIView()
    
    private let exitButton = UIButton(type: .custom)
    private let shareButton = UIButton(type: .custom)
    
    // Constants
    
    private let exitButtonSize: CGFloat = 50
    private let exitButtonPad: CGFloat = 10
    
    private var statusBarHidden = false
    
    // Variables
    
    public var itemName: String?
    public var shareLink: String?
    
    public var backgroundColor: UIColor = UIColor.white{
        didSet{
            
            UIView.animate(withDuration: 0.3) {
                
                self.view.backgroundColor = self.backgroundColor
            }
        }
    }
    
    public fileprivate(set) var currentPage = 0{
        didSet{
            updatePageControl()
        }
    }
    
    public fileprivate(set) var originalPage = 0
    
    public var imageLinks: Array<String> = []{
        didSet{
            updatePageControl()
        }
    }
    
    public var enablePageControl = false{
        didSet{
            pageControl.isHidden = !enablePageControl
        }
    }
    
    public var tapToClose: Bool = false{
        didSet{
            
            updateGesture()
        }
    }
    
    public var customActivities: [UIActivity] = []
    
    // Hide bottom bar
    public override var hidesBottomBarWhenPushed: Bool{
        get{
            
            return true
        }
        set{ }
    }
    
    public var imageOffset = CGPoint(x: 0, y: 0) {
        didSet{
            
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    public init(currentIndex: Int, links: [String], placeholder: UIImage? = nil, startingFrame: CGRect? = nil){
        
        super.init(nibName: nil, bundle: nil)
        
        modalTransitionStyle = .crossDissolve
        //        modalPresentationStyle = .fullScreen
        
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
        
        let exitImage = UIImage(named: "close-icon", in: Bundle(for: FLGalleryPageVC.self), compatibleWith: nil)
        
        exitButton.setImage(exitImage, for: .normal)
        
        exitButton.setTitle("", for: .normal)
        exitButton.addTarget(self, action: #selector(FLGalleryPageVC.donePressed), for: .touchUpInside)
        
        let shareImage = UIImage(named: "share-icon", in: Bundle(for: FLGalleryPageVC.self), compatibleWith: nil)
        
        shareButton.setImage(shareImage, for: .normal)
        
        shareButton.setTitle("", for: .normal)
        shareButton.addTarget(self, action: #selector(FLGalleryPageVC.sharePressed), for: .touchUpInside)
        
        //        UIEdgeInsetsMake(<#T##top: CGFloat##CGFloat#>, <#T##left: CGFloat##CGFloat#>, <#T##bottom: CGFloat##CGFloat#>, <#T##right: CGFloat##CGFloat#>)
        
        buttonContainer.backgroundColor = UIColor(white: 1, alpha: 0.2)
        buttonContainer.layer.cornerRadius = exitButtonSize / 2
        
        pageControl.backgroundColor = UIColor(white: 1, alpha: 0.2)
        pageControl.layer.cornerRadius = 10
        pageControl.hidesForSinglePage = true
        
        pageControl.pageIndicatorTintColor = UIColor(white: 0.9, alpha: 0.8)
        pageControl.currentPageIndicatorTintColor = UIColor(white: 0.2, alpha: 0.8)
        
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
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.statusBarHidden = true
        
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.statusBarHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        
        return .slide
    }
    
    public override var prefersStatusBarHidden: Bool{
        
        return statusBarHidden
    }
    
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let _ = shareLink {
            
            exitButton.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 5, bottom: 10, right: 15)
            shareButton.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 15, bottom: 10, right: 5)
            
            shareButton.alpha = 1
            
            buttonContainer.frame = CGRect(x: view.bounds.width - (exitButtonSize) * 2 - exitButtonPad, y: 14, width: exitButtonSize * 2, height: exitButtonSize)
            exitButton.frame = CGRect(x: exitButtonSize, y: 0, width: exitButtonSize, height: exitButtonSize)
            shareButton.frame = CGRect(x: 0, y: 0, width: exitButtonSize, height: exitButtonSize)
            
        }else {
            
            exitButton.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
            shareButton.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
            
            shareButton.alpha = 0
            
            buttonContainer.frame = CGRect(x: view.bounds.width - exitButtonSize - exitButtonPad, y: 14, width: exitButtonSize, height: exitButtonSize)
            exitButton.frame = CGRect(x: 0, y: 0, width: exitButtonSize, height: exitButtonSize)
            shareButton.frame = CGRect.zero
        }
        
        if !self.isBeingDismissed{
            
            pageVC.view.frame = view.bounds
        }
        
        let pageControlWidth = CGFloat(pageControl.numberOfPages) * 20
        pageControl.frame = CGRect(x: (view.bounds.width - pageControlWidth) / 2, y: view.bounds.height - 50, width: pageControlWidth, height: 20)
    }
    
    public func isModal() -> Bool{
        
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }
    
    public func setCurrentImagePage(page: Int){
        
        currentPage = page
        originalPage = page
        
        updatePageControl()
        
        let vc = self.viewControllerForIndex(index: self.currentPage)
        self.pageVC.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
    }
    
    public func imageFrame(forPage page: Int) -> CGRect{
        
        if self.modalPresentationStyle == .fullScreen {
            
            self.view.frame = UIApplication.shared.keyWindow?.bounds ?? self.view.frame
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
        var rect = view.bounds
        
        if page == currentPage,
            let vc = self.pageVC.viewControllers?.first as? FLGalleryImageVC{
            
            vc.view.frame = self.view.frame
            vc.view.layoutIfNeeded()
            rect = vc.imageView.frame
            
        } else if let vc = self.viewControllerForIndex(index: self.currentPage) as? FLGalleryImageVC{
            
            vc.view.frame = self.view.frame
            vc.view.layoutIfNeeded()
            
            rect = vc.imageView.frame
        }
        
        return rect
    }
    
    public func imageView(forPage page: Int) -> UIView{
        
        if page == currentPage,
            let vc = self.pageVC.viewControllers?.first as? FLGalleryImageVC{
            
            vc.view.layoutIfNeeded()
            
            return vc.imageView
            
        } else if let vc = self.viewControllerForIndex(index: self.currentPage) as? FLGalleryImageVC{
            
            vc.view.layoutIfNeeded()
            
            return vc.imageView
        }
        
        return self.view
    }
    
    private func updatePageControl(){
        
        pageControl.numberOfPages = imageLinks.count
        pageControl.currentPage = currentPage
    }
    
    private func setupPageViewController(){
        
        pageVC.view.backgroundColor = UIColor.clear
        pageVC.delegate = self
        pageVC.dataSource = self
        
        view.addSubview(pageVC.view)
    }
    
    fileprivate func viewControllerForIndex(index: Int) -> UIViewController{
        
        let galleryImageVC = FLGalleryImageVC(index: index, imageURL: imageLinks[index])
        
        galleryImageVC.placeHolderImage = self.dataSource?.gallery(galleryVC: self, placeholderImageForIndex: index)
        galleryImageVC.imageOffset = self.imageOffset
        
        self.updateGesture()
        
        return galleryImageVC
    }
    
    func updateGesture() {
        
        if let viewControllers = self.pageVC.viewControllers,
            tapToClose,
            viewControllers.count > self.currentPage{
            
            if let vc = viewControllers[self.currentPage] as? FLGalleryImageVC{
                
                vc.setupSingleTap(target: self, action: #selector(FLGalleryPageVC.donePressed(sender:)))
            }
        }
    }
    
    @objc func gesturePanned(sender: UIGestureRecognizer) {
        
        guard let panGesture = sender as? UIPanGestureRecognizer else {
            
            return
        }
        
        let translation = panGesture.translation(in: pageVC.view)
        
        switch panGesture.state {
        case .began: break
        case .changed:
            
            self.pageVC.view.frame.origin.y = translation.y
            
        case .ended:
            
            if abs(translation.y) / self.pageVC.view.bounds.height > 0.20 {
                
                self.dismiss(animated: true, completion: nil)
                
            }else{
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    self.pageVC.view.frame.origin.y = 0
                    self.view.alpha = 1
                })
            }
            
        default:break
        }
    }
    
    @objc public func donePressed(sender: UITapGestureRecognizer? = nil){
        
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc public func sharePressed(sender: Any? = nil){
        
        guard imageLinks.count > 0 else {
            
            return
        }
        
        guard let imageURL = URL(string: imageLinks[currentPage])
            else{
                
                return
        }
        
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
                    
                    if let sender = sender as? UIBarButtonItem{
                        
                        popoverController.barButtonItem = sender
                        
                    }else if let sender = sender as? UIGestureRecognizer{
                        
                        popoverController.sourceView = sender.view
                        
                    }else if let sender = sender as? UIButton{
                        
                        popoverController.sourceView = sender
                    }
                }
                
                self.present(vc, animated: true, completion: nil)
                
                vc.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
                    
                    self.delegate?.gallery(galleryVC: self, didShareActivity: activityType, currentIndex: self.currentPage)
                }
            }
        })
    }
    
    public override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: UIPageViewControllerDataSource
extension FLGalleryPageVC: UIPageViewControllerDataSource{
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if (currentPage == 0){
            return nil
            
        }else{
            return self.viewControllerForIndex(index: currentPage - 1)
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if (currentPage == imageLinks.count - 1){
            return nil
            
        }else{
            return self.viewControllerForIndex(index: currentPage + 1)
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let vc = pageViewController.viewControllers!.first as? FLGalleryImageVC{
            
            if let index = vc.index,
                index != currentPage{
                
                self.currentPage = index
            }
        }
    }
}

// MARK: UIPageViewControllerDelegate
extension FLGalleryPageVC: UIPageViewControllerDelegate{
    
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        if let vc = pendingViewControllers.first as? FLGalleryImageVC{
            
            if let index = vc.index,
                index != currentPage{
                
                self.currentPage = index
            }
        }
        
        print("[Transition] self.currentPage: \(self.currentPage)")
    }
}
