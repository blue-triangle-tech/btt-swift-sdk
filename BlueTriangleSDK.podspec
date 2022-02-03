Pod::Spec.new do |s|
  s.name             = 'BlueTriangleSDK'
  s.version          = '3.0.0-beta'
  s.summary          = 'BlueTriangleSDK exposes methods to send analytics and crash data to the Blue Triangle portal'
  s.description      = <<-DESC
  BlueTriangleSDK exposes methods to send analytics and crash data to the Blue Triangle portal via HTTP Post
                       DESC

  s.homepage         = 'https://www.bluetriangle.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Joel Aliff' => 'joel.aliff@bluetriangletech.com' }
  s.source           = { :git => 'https://github.com/blue-triangle-tech/btt-swift-sdk.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_BlueTriangle'

  s.swift_version = '5.1'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '6.0'

  s.source_files = 'Sources/BlueTriangle/**/*.swift'

end
