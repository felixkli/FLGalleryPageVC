Pod::Spec.new do |s|

  s.name         = "FLGalleryPageVC"
  s.version      = "0.9.5"
  s.summary      = "UIPageViewController made to show gallery with zoom"
  s.homepage     = "https://github.com/felixkli/FLGalleryPageVC"
  s.license      = 'MIT'
  s.author       = { "Felix Li" => "li.felix162@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/felixkli/FLGalleryPageVC.git", :tag => s.version.to_s }
  s.source_files = "Source/*.swift"
  s.dependency 'SDWebImage'
  s.resources = 'Resources/Media.xcassets'
  s.swift_version = '4.2'
end
