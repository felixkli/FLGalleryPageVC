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
    var imageSize = CGSize.zero
    
    var placeHolderImage: UIImage?
    
    var loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    public var imageOffset = CGPoint(x: 0, y: 0) {
        didSet{
            
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    
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
        
        imageView.frame.size = self.imageView.proportionalSizeToFitMaxSize(maxSize: self.view.bounds.size)
        scrollView.contentSize = imageView.bounds.size
        loadingIndicator.center = view.center
        
        view.backgroundColor = UIColor.clear
        scrollView.backgroundColor = UIColor.clear
        imageView.backgroundColor = UIColor.clear
        
        centerScrollContent()
        
        print("[gallery]")
        print("[gallery] imageView: \(imageView.frame)")
        print("[gallery] scrollView: \(scrollView.frame)")
        print("[gallery] scrollView: \(scrollView.zoomScale)")
        print("[gallery]")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        scrollView.zoomScale = 0.0;
    }
    
    func setupScrollView(){
        
        scrollView.minimumZoomScale=1.0;
        scrollView.maximumZoomScale=3.0;
        scrollView.delegate=self;
        scrollView.clipsToBounds = true;
        scrollView.backgroundColor = UIColor.green
        view.addSubview(scrollView)
    }
    
    func setupImageCropper(){
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(FLGalleryImageVC.imgsScrlViewLongPressed(sender:)))
        
        doubleTap = UITapGestureRecognizer(target: self, action: #selector(FLGalleryImageVC.handleDoubleTap(sender:)))
        doubleTap.numberOfTapsRequired = 2
        
        imageView.contentMode = UIViewContentMode.center
        imageView.isUserInteractionEnabled = true
        //        imageView.backgroundColor = UIColor.black
        imageView.addGestureRecognizer(longPressRecognizer)
        imageView.addGestureRecognizer(doubleTap)
        
        scrollView.addSubview(imageView)
        scrollView.addSubview(loadingIndicator)
    }
    
    func retrieveImage(){
        
        if let _ = placeHolderImage{
            
            self.scrollView.maximumZoomScale = 3.0
            self.scrollView.minimumZoomScale = 1.0
            
            self.imageSize = self.imageView.proportionalSizeToFitMaxSize(maxSize: self.view.bounds.size, placeHolder: placeHolderImage)
            self.imageView.frame.size = self.imageSize
            self.imageView.contentMode = UIViewContentMode.scaleAspectFit
            self.centerScrollContent()
            
        }else{
            
            loadingIndicator.startAnimating()
        }
        
        self.imageView.sd_setImage(with: URL(string: imageURL), placeholderImage: placeHolderImage, options: [], progress: nil) { (image, error, cacheType, url) in
            
            self.imageSize = self.imageView.proportionalSizeToFitMaxSize(maxSize: self.view.bounds.size)
            //            self.imageView.frame.origin = self.imageOffset
            self.imageView.frame.size = self.imageSize
            self.imageView.contentMode = UIViewContentMode.scaleAspectFit
            self.centerScrollContent()
            
            if let _ = self.placeHolderImage {
                
            }else{
                
                self.imageView.alpha = 0
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.imageView.alpha = 1
            })
            
            self.loadingIndicator.stopAnimating()
            
            self.scrollView.maximumZoomScale = 3.0
            self.scrollView.minimumZoomScale = 1.0;
        }
    }
    
    func imgsScrlViewLongPressed(sender: UILongPressGestureRecognizer)
    {
        print("longpressed")
        if (sender.state == UIGestureRecognizerState.ended) {
            print("Long press Ended");
            
        } else if (sender.state == UIGestureRecognizerState.began) {
            print("Long press detected.");
            
            let imgView: UIImageView = sender.view as! UIImageView
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
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        
        if error == nil {
            
            let ac = UIAlertController(title: "Success!", message: "Image has been saved.", preferredStyle: .alert)
            present(ac, animated: true, completion: nil)
            
            let delayTime = DispatchTime.now() + 1.5
            DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
                
                ac.dismiss(animated: true, completion: nil)
            })
            
        } else {
            
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(ac, animated: true, completion: nil)
        }
    }
    
    func handleDoubleTap(sender: UITapGestureRecognizer){
        
        if scrollView.zoomScale >= 2{
            scrollView.setZoomScale(0.0, animated: true)
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
}

extension FLGalleryImageVC: UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        if self.scrollView.maximumZoomScale == self.scrollView.minimumZoomScale{
            
            return nil
            
        }else{
            
            return self.imageView
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        self.centerScrollContent()
    }
    
    func centerScrollContent(){
        
        let screenSize = scrollView.bounds.size
        let boundsSize = CGSize(width: screenSize.width, height: screenSize.height )
        
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
        
        self.imageView.frame = CGRect(x: contentsFrame.origin.x + imageOffset.x, y: contentsFrame.origin.y + imageOffset.y, width: contentsFrame.width, height: contentsFrame.height)
        
        //        self.imageView.frame = contentsFrame;
    }
}

extension UIImageView{
    
    func proportionalSizeToFitMaxSize(maxSize: CGSize, placeHolder: UIImage? = nil) -> CGSize{
        
        var proportionalSize = CGSize.zero
        
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
            
            proportionalSize = CGSize(width: width, height: height)
            
        } else if let placeHolderImage = placeHolder{
            
            var width: CGFloat = 0
            var height: CGFloat = 0
            
            let maxSizeAspectRatio = maxSize.width / maxSize.height
            let imageAspectRatio = placeHolderImage.size.width / placeHolderImage.size.height
            
            if maxSizeAspectRatio > imageAspectRatio{
                
                height = maxSize.height
                width = placeHolderImage.size.width/placeHolderImage.size.height * height
            }else{
                
                width = maxSize.width
                height = placeHolderImage.size.height/placeHolderImage.size.width * width
            }
            
            proportionalSize = CGSize(width: width, height: height)
        }
        
        return proportionalSize
    }
}
