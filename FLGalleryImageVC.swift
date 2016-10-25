//
//  FLGalleryImageVC.swift
//  hypebeast
//
//  Created by Felix Li on 31/7/15.
//

import Foundation
import SDWebImage

class FLGalleryImageVC: UIViewController {
    
    let imageView = UIImageView()
    let scrollView = UIScrollView()
    
    var index: Int!
    var imageURL: String!
    var doubleTap: UITapGestureRecognizer!
    var imageSize = CGSizeZero
    
    var placeHolderImage: UIImage?
    
    var loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    init(index: Int, imageURL: String){
        super.init(nibName: nil, bundle: nil)
        
        self.index = index
        self.imageURL = imageURL
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScrollView()
        setupImageCropper()
        retrieveImage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.zoomScale = 0.0;
        scrollView.frame = view.bounds
        
        imageView.frame.size = self.imageView.proportionalSizeToFitMaxSize(self.view.bounds.size)
        scrollView.contentSize = imageView.bounds.size
        loadingIndicator.center = view.center
        
        view.backgroundColor = UIColor.clearColor()
        scrollView.backgroundColor = UIColor.clearColor()
        imageView.backgroundColor = UIColor.clearColor()
        
        centerScrollContent()
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        scrollView.zoomScale = 0.0;
    }
    
    func setupScrollView(){
        
        scrollView.minimumZoomScale=1.0;
        scrollView.maximumZoomScale=3.0;
        scrollView.delegate=self;
        scrollView.clipsToBounds = true;
        
        view.addSubview(scrollView)
    }
    
    func setupImageCropper(){
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(FLGalleryImageVC.imgsScrlViewLongPressed(_:)))
        
        doubleTap = UITapGestureRecognizer(target: self, action: #selector(FLGalleryImageVC.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        
        imageView.contentMode = UIViewContentMode.Center
        imageView.userInteractionEnabled = true
        imageView.backgroundColor = UIColor.blackColor()
        imageView.addGestureRecognizer(longPressRecognizer)
        imageView.addGestureRecognizer(doubleTap)
        
        scrollView.addSubview(imageView)
        scrollView.addSubview(loadingIndicator)
    }
    
    func retrieveImage(){
        
        if let _ = placeHolderImage{
            
            self.scrollView.maximumZoomScale = 1.0
            self.scrollView.minimumZoomScale = 1.0
            
        }else{
            
            loadingIndicator.startAnimating()
        }
        
        imageView.sd_setImageWithURL(
            NSURL(string: imageURL),
            placeholderImage: placeHolderImage,
            completed: { (image, error, cacheType, url) in
                
                self.imageSize = self.imageView.proportionalSizeToFitMaxSize(self.view.bounds.size)
                self.imageView.frame.size = self.imageSize
                self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
                self.centerScrollContent()
                
                self.imageView.alpha = 0
                UIView.animateWithDuration(0.3, animations: { () in
                    self.imageView.alpha = 1
                })
                
                self.loadingIndicator.stopAnimating()
                
                self.scrollView.maximumZoomScale = 3.0
                self.scrollView.minimumZoomScale = 1.0;
        })
    }
    
    func imgsScrlViewLongPressed(sender: UILongPressGestureRecognizer)
    {
        print("longpressed")
        if (sender.state == UIGestureRecognizerState.Ended) {
            print("Long press Ended");
            
        } else if (sender.state == UIGestureRecognizerState.Began) {
            print("Long press detected.");
            
            let imgView: UIImageView = sender.view as! UIImageView
            let saveImgAS = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            saveImgAS.addAction(UIAlertAction(title: "Save Image", style: .Default, handler: { (action) in
                
                // Save image here
                UIImageWriteToSavedPhotosAlbum(imgView.image!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }))
            
            saveImgAS.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            if let popoverController = saveImgAS.popoverPresentationController {
                
                let point = sender.locationInView(imgView)
                
                popoverController.sourceView = sender.view
                popoverController.sourceRect = CGRectMake(point.x + 30, point.y, 1, 1)
            }
            
            self.presentViewController(saveImgAS, animated: true, completion: nil)
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
        
        if error == nil {
            
            let ac = UIAlertController(title: "Success!", message: "Image has been saved.", preferredStyle: .Alert)
            presentViewController(ac, animated: true, completion: nil)
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                                          Int64(1.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                ac.dismissViewControllerAnimated(true, completion: nil)
            }
            
        } else {
            
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    func handleDoubleTap(sender: UITapGestureRecognizer){
        
        if scrollView.zoomScale >= 2{
            scrollView.setZoomScale(0.0, animated: true)
        }else{
            let  pointInView = sender.locationInView(self.imageView)
            
            var newZoomScale = self.scrollView.zoomScale * 2
            newZoomScale = min(newZoomScale, self.scrollView.maximumZoomScale);
            
            let scrollViewSize = self.scrollView.bounds.size;
            
            let w = scrollViewSize.width / newZoomScale;
            let h = scrollViewSize.height / newZoomScale;
            let x = pointInView.x - (w / 2.0);
            let y = pointInView.y - (h / 2.0);
            
            let rectToZoomTo = CGRectMake(x, y, w, h);
            
            self.scrollView.zoomToRect(rectToZoomTo, animated: true)
        }
    }
}

extension FLGalleryImageVC: UIScrollViewDelegate{
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        
        if self.scrollView.maximumZoomScale == self.scrollView.minimumZoomScale{
            
            return nil
            
        }else{
            
            return self.imageView
        }
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.centerScrollContent()
    }
    
    func centerScrollContent(){
        
        let screenSize = scrollView.bounds.size
        let boundsSize = CGSizeMake(screenSize.width, screenSize.height )
        
        var contentsFrame = self.imageView.frame
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0;
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        self.imageView.frame = contentsFrame;
    }
}

extension UIImageView{
    
    func proportionalSizeToFitMaxSize(maxSize: CGSize) -> CGSize{
        
        var proportionalSize = CGSizeZero
        
        if let image = self.image{
            
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
            
            proportionalSize = CGSizeMake(width, height)
        }
        
        return proportionalSize
    }
}
