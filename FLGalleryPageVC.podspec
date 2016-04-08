Pod::Spec.new do |s|

  s.name         = "FLGalleryPageVC"
  s.version      = "0.0.1"
  s.summary      = "UIPageViewController made to show gallery with zoom"
  s.homepage     = "https://github.com/felixkli/FLGalleryPageVC"
  s.license      = 'MIT'
  s.author             = { "Felix Li" => "li.felix162@gmail.com" }
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/felixkli/FLGalleryPageVC.git", :tag => "0.0.1" }
  s.source_files = 'FLGalleryPageVC.swift', 'FLGalleryImageVC.swift'
  s.resources             = "Resources/*.xcassets"
end