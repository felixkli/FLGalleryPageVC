//
//  FLGalleryPageVC.swift
//  hypebeast
//
//  Created by Felix Li on 31/7/15.
//

import Foundation

public class FLGalleryPageVC: UIViewController {
    
    private let pageControl =  UIPageControl()
    private let exitButton = UIButton(type: .custom)
    private let exitButtonSize: CGFloat = 50
    private let exitButtonPad: CGFloat = 20
    
    private var statusBarHidden = false
    
    public var pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    public var placeHolderImage: UIImage? {
        didSet{
            
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
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
        modalPresentationStyle = .fullScreen
        
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
        exitButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        exitButton.layer.cornerRadius = exitButtonSize / 2
        exitButton.backgroundColor = UIColor(white: 1, alpha: 0.2)
        
        pageControl.backgroundColor = UIColor(white: 1, alpha: 0.2)
        pageControl.layer.cornerRadius = 10
        pageControl.hidesForSinglePage = true
        
        pageControl.pageIndicatorTintColor = UIColor(white: 0.9, alpha: 0.8)
        pageControl.currentPageIndicatorTintColor = UIColor(white: 0.2, alpha: 0.8)
        
        setupPageViewController()
        updatePageControl()
        
        view.addSubview(pageControl)
        view.addSubview(exitButton)
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
        
        exitButton.frame = CGRect(x: view.bounds.width - exitButtonSize - exitButtonPad + 10, y: 14, width: exitButtonSize, height: exitButtonSize)
        pageVC.view.frame = view.bounds
        
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
        
        updatePageControl()
        
        let vc = self.viewControllerForIndex(index: self.currentPage)
        self.pageVC.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
    }
    
    public func imageFrame(forPage page: Int) -> CGRect{
        
        if page == currentPage,
            let vc = self.pageVC.viewControllers?.first as? FLGalleryImageVC{
            
            vc.view.layoutIfNeeded()
            
            return vc.imageView.frame
            
        } else if let vc = self.viewControllerForIndex(index: self.currentPage) as? FLGalleryImageVC{
            
            vc.view.layoutIfNeeded()
            
            return vc.imageView.frame
        }
        
        return view.bounds
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
        
        galleryImageVC.placeHolderImage = self.placeHolderImage
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
    
    public func donePressed(sender: UITapGestureRecognizer? = nil){
        
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    public override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        
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
