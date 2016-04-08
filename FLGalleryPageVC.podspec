Pod::Spec.new do |s|

  s.name         = "FLGalleryPageVC"
  s.version      = "0.0.9"
  s.summary      = "UIPageViewController made to show gallery with zoom"
  s.homepage     = "https://github.com/felixkli/FLGalleryPageVC"
  s.license      = 'MIT'
  s.author             = { "Felix Li" => "li.felix162@gmail.com" }
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/felixkli/FLGalleryPageVC.git", :tag => s.version.to_s }
  s.source_files = 'FLGalleryPageVC.swift', 'FLGalleryImageVC.swift'
  s.dependency 'SDWebImage', '3.7.5'
  s.resource_bundle = { 'FLGalleryPageVC' => ['Resources/Media.xcassets'] }
  s.frameworks            = 'UIKit', 'Foundation'
  s.requires_arc          = true
end
