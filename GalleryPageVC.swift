//
//  GalleryPageVC.swift
//  hypebeast
//
//  Created by Felix Li on 31/7/15.
//

import Foundation

class GalleryPageVC: UIViewController {
    
    private let pageControl =  UIPageControl()
    private let exitButton = UIButton(type: UIButtonType.Custom)
    private let exitButtonSize: CGFloat = 50
    private let exitButtonPad: CGFloat = 20
    
    var pageVC = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)

    private(set) var currentPage = 0{
        didSet{
            updatePageControl()
        }
    }

    var imageLinks: Array<String> = []{
        didSet{
            updatePageControl()
        }
    }

    var enablePageControl = false{
        didSet{
            pageControl.hidden = !enablePageControl
        }
    }
    
    init(currentIndex: Int, links: [String]){
        
        super.init(nibName: nil, bundle: nil)

        modalTransitionStyle = .CrossDissolve
        modalPresentationStyle = .OverFullScreen
        
        currentPage = currentIndex
        imageLinks = links
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        modalPresentationCapturesStatusBarAppearance = true
        
        view.backgroundColor = UIColor.whiteColor()
        
        exitButton.setImage(UIImage(named: "close-icon"), forState: .Normal)
        exitButton.setTitle("", forState: .Normal)
        exitButton.addTarget(self, action: #selector(donePressed), forControlEvents: .TouchUpInside)
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
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Slide
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        exitButton.frame = CGRectMake(view.bounds.width - exitButtonSize - exitButtonPad + 10, 14, exitButtonSize, exitButtonSize)
        pageVC.view.frame = view.bounds
        
        let pageControlWidth = CGFloat(pageControl.numberOfPages) * 20
        pageControl.frame = CGRectMake((view.bounds.width - pageControlWidth) / 2, view.bounds.height - 50, pageControlWidth, 20)
    }
    
    func isModal() -> Bool{
        
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }
    
    func setCurrentImagePage(page: Int){
        
        currentPage = page
        
        updatePageControl()
        dispatch_async(dispatch_get_main_queue(),{
            
            let vc = self.viewControllerForIndex(self.currentPage)
            self.pageVC.setViewControllers([vc], direction: .Forward, animated: false, completion: nil)
        })
    }
    
    private func updatePageControl(){
        
        pageControl.numberOfPages = imageLinks.count
        pageControl.currentPage = currentPage
    }
    
    private func setupPageViewController(){
        
        pageVC.view.backgroundColor = UIColor.whiteColor()
        pageVC.delegate = self
        pageVC.dataSource = self
        
        view.addSubview(pageVC.view)
    }
    
    private func viewControllerForIndex(index: Int) -> UIViewController{
        
        return GalleryImageVC(index: index, imageURL: imageLinks[index])
    }

    func donePressed(){
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: UIPageViewControllerDataSource
extension GalleryPageVC: UIPageViewControllerDataSource{
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?{
        
        if (currentPage == 0){
            return nil
            
        }else{
            return viewControllerForIndex(currentPage - 1)
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?{
        
        if (currentPage == imageLinks.count - 1){
            return nil
            
        }else{
            return viewControllerForIndex(currentPage + 1)
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let vc = pageViewController.viewControllers!.first as? GalleryImageVC{
        
            if vc.index != currentPage{
                currentPage = vc.index
            }
        }
    }
}

// MARK: UIPageViewControllerDelegate
extension GalleryPageVC: UIPageViewControllerDelegate{
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        
        if let vc = pendingViewControllers.first as? GalleryImageVC{
            
            if vc.index != currentPage{
                currentPage = vc.index
            }
        }
    }
}
