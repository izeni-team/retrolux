#
# Be sure to run `pod lib lint Retrolux.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Retrolux'
  s.version          = '0.5.3'
  s.summary          = 'An all in one networking solution, like Retrofit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
There are many good networking libraries out there already for iOS. Alamofire, AFNetworking, and Moya, etc., are all great libraries.

What makes this framework unique is that each endpoint can be consicely described and implemented. No subclassing, protocol implementations, functions to implement, or extra modules to download. It comes with JSON, Multipart, and URL Encoding support out of the box. In short, it aims to optimize, as much as possible, the end-to-end process of network API consumption.

The purpose of this framework is not just to abstract away networking details, but also to provide a Retrofit-like workflow, where endpoints can be described--not implemented.
                       DESC

  s.homepage         = 'https://github.com/izeni-team/retrolux'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bryan Henderson' => 'bhenderson@startstudio.com' }
  s.source           = { :git => 'https://github.com/izeni-team/retrolux.git', :tag => 'v%s' % [s.version.to_s] }
  # s.social_media_url = 'https://twitter.com/cbh2000'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Retrolux/**/*'
  
  # s.resource_bundles = {
  #   'Retrolux' => ['Retrolux/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
