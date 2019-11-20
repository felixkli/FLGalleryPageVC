//
//  FLGalleryImageVC.swift
//  hypebeast
//
//  Created by Felix Li on 31/7/15.
//

import Foundation

class FLGalleryImageVC: UIViewController {
    
    public let imageView = UIImageView()
    public var index: Int?
    public var imageURL: String?
    
    public var placeHolderImage: UIImage?
    
    private var longPress: UILongPressGestureRecognizer?
    private var doubleTap: UITapGestureRecognizer?
    private var singleTap: UITapGestureRecognizer?
    
    private var loadingIndicator = UIActivityIndicatorView(style: .gray)
    
    public var imageOffset = CGPoint(x: 0, y: 0) {
        didSet{
            
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    private let scrollView = UIScrollView()
    
    public var scrollViewContentInset: UIEdgeInsets {
        
        return scrollView.contentInset
    }
    
    init(index: Int, imageURL: String){
        super.init(nibName: nil, bundle: nil)
        
        self.index = index
        self.imageURL = imageURL
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupScrollView()
        setupImageCropper()
        retrieveImage()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.zoomScale = 0.0;
        scrollView.frame = view.bounds
        
        imageView.frame.size = self.imageView.proportionalSizeToFitMaxSize(maxSize: self.view.bounds.size)
        scrollView.contentSize = imageView.bounds.size
        loadingIndicator.center = view.center
        
        view.backgroundColor = UIColor.clear
        scrollView.backgroundColor = UIColor.clear
        imageView.backgroundColor = UIColor.clear
        
        centerScrollContent()
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        scrollView.zoomScale = 0.0;
    }
    
    func setupScrollView(){
        
        if #available(iOS 11.0, *) {
            
            scrollView.contentInsetAdjustmentBehavior = .never
            
        } else {
            
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 3.0;
        scrollView.delegate = self
        scrollView.clipsToBounds = true
        
        view.addSubview(scrollView)
    }
    
    func setupImageCropper(){
        
        if longPress == nil{
            longPress = UILongPressGestureRecognizer(target: self, action: #selector(FLGalleryImageVC.imgsScrlViewLongPressed(sender:)))
            
            imageView.addGestureRecognizer(longPress!)
        }
        
        if doubleTap == nil {
            doubleTap = UITapGestureRecognizer(target: self, action: #selector(FLGalleryImageVC.handleDoubleTap(sender:)))
            doubleTap?.numberOfTapsRequired = 2
            doubleTap?.numberOfTouchesRequired = 1
            
            imageView.addGestureRecognizer(doubleTap!)
        }
        
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        scrollView.addSubview(imageView)
        scrollView.addSubview(loadingIndicator)
    }
    
    func setupSingleTap(target: Any?, action: Selector?){
        
        if singleTap == nil {
            singleTap = UITapGestureRecognizer(target: target, action: action)
            singleTap?.numberOfTouchesRequired = 1
            singleTap?.numberOfTapsRequired = 1
            singleTap?.require(toFail: doubleTap!)
            
            imageView.addGestureRecognizer(singleTap!)
        }
    }
    
    func retrieveImage(){
        
        if let _ = placeHolderImage{
            
            self.imageView.frame.size = self.imageView.proportionalSizeToFitMaxSize(maxSize: self.view.bounds.size, placeHolder: placeHolderImage)
            self.centerScrollContent()
            
        }else{
            
            loadingIndicator.startAnimating()
        }
        
        guard let imageURL = imageURL else {
            
            return
        }
        
        self.imageView.sd_setImage(with: URL(string: imageURL), placeholderImage: placeHolderImage, options: [.avoidAutoSetImage], progress: nil) { (image, error, cacheType, url) in
            
            let currentScale = self.scrollView.zoomScale
            let currentOffset = self.scrollView.contentOffset
            
            self.scrollView.zoomScale = 1
            self.scrollView.contentOffset = CGPoint.zero
            
            self.imageView.image = image
            
            self.imageView.frame.size = self.imageView.proportionalSizeToFitMaxSize(maxSize: self.view.bounds.size)
            
            self.centerScrollContent()
            
            if self.placeHolderImage == nil {
                
                self.imageView.alpha = 0
            }else {
                
                self.scrollView.zoomScale = currentScale
                self.scrollView.contentOffset = currentOffset
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.imageView.alpha = 1
            })
            
            self.loadingIndicator.stopAnimating()
        }
    }
    
    @objc func imgsScrlViewLongPressed(sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .began:
            
            guard let imgView: UIImageView = sender.view as? UIImageView else { break }
            
            let saveImgAS = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            saveImgAS.addAction(UIAlertAction(title: "Save Image", style: .default, handler: { (action) in
                
                // Save image here
                UIImageWriteToSavedPhotosAlbum(imgView.image!, self, #selector(self.image(image:didFinishSavingWithError:contextInfo:)), nil)
            }))
            
            saveImgAS.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            if let popoverController = saveImgAS.popoverPresentationController {
                
                let point = sender.location(in: imgView)
                
                popoverController.sourceView = sender.view
                popoverController.sourceRect = CGRect(x: point.x + 30, y: point.y, width: 1, height: 1)
            }
            
            self.present(saveImgAS, animated: true, completion: nil)

        default: break
        }
    }
    
    @objc func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        
        guard error == nil else {
            
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(ac, animated: true, completion: nil)
            
            return
        }
        
        let ac = UIAlertController(title: "Success!", message: "Image has been saved.", preferredStyle: .alert)
        present(ac, animated: true, completion: nil)
        
        let delayTime = DispatchTime.now() + 1.5
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            
            ac.dismiss(animated: true, completion: nil)
        })
    }
    
    @objc func handleDoubleTap(sender: UITapGestureRecognizer){
        
        if scrollView.zoomScale >= 2{
            
            resetZoom()
            
        }else{
            
            let pointInView = sender.location(in: self.imageView)
            
            var newZoomScale = self.scrollView.zoomScale * 2
            newZoomScale = min(newZoomScale, self.scrollView.maximumZoomScale);
            
            let scrollViewSize = self.scrollView.bounds.size;
            
            let w = scrollViewSize.width / newZoomScale;
            let h = scrollViewSize.height / newZoomScale;
            let x = pointInView.x - (w / 2.0);
            let y = pointInView.y - (h / 2.0);
            
            let rectToZoomTo = CGRect(x: x, y: y, width: w, height: h);
            
            self.scrollView.zoom(to: rectToZoomTo, animated: true)
        }
    }
    
    func resetZoom(animated: Bool = true) {
        
        scrollView.setZoomScale(0.0, animated: animated)
    }
    
    func centerScrollContent(){
        
        let screenSize = scrollView.bounds.size
        let boundsSize = CGSize(width: screenSize.width, height: screenSize.height )
        
        var contentsFrame = self.imageView.frame
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = -imageOffset.x
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = -imageOffset.y
        }
        
        self.scrollView.contentInset = UIEdgeInsets(top: contentsFrame.origin.y, left: contentsFrame.origin.x, bottom: contentsFrame.origin.y, right: contentsFrame.origin.x)
    }
}

extension FLGalleryImageVC: UIScrollViewDelegate{
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        if self.scrollView.maximumZoomScale == self.scrollView.minimumZoomScale{
            
            return nil
            
        }else{
            
            return self.imageView
        }
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        self.centerScrollContent()
    }
}

public extension UIImageView{
    
    func proportionalSizeToFitMaxSize(maxSize: CGSize, placeHolder: UIImage? = nil) -> CGSize{
        
        var proportionalSize = CGSize.zero
        
        let currentImage = self.image ?? placeHolder
        
        if let image = currentImage{
            
            var width: CGFloat = 0
            var height: CGFloat = 0
            
            let maxSizeAspectRatio = maxSize.width / maxSize.height
            let imageAspectRatio = image.size.width / image.size.height
            
            if maxSizeAspectRatio > imageAspectRatio{
                
                height = maxSize.height
                width = image.size.width/image.size.height * height
            }else{
                
                width = maxSize.width
                height = image.size.height/image.size.width * width
            }
            
            proportionalSize = CGSize(width: width, height: height)
        }
        
        return proportionalSize
    }
}
