Pod::Spec.new do |s|
  s.name             = 'tvhclient-lib'
  s.version          = '3.0.2'
  s.platforms	     = { 'ios' => '8.0', 'tvos' => '9.0' }
  s.summary          = 'Tvheadend iOS library enables you to create apps that connect to tvheadend. This is the base of TvhClient'

  s.description      = <<-DESC
This library contains shared code between tvhclient-ios and tvhclient-tvOS. It is also all the internal networking code that talks to tvheadend.
                       DESC

  s.homepage         = 'https://github.com/zipleen/tvheadend-ios-lib'
  s.license          = { :type => 'MPL-2', :file => 'LICENSE.md' }
  s.author           = { 'Luis Fernandes' => 'zipleen@gmail.com' }
  s.source           = { :git => 'https://github.com/zipleen/tvheadend-ios-lib.git', :tag => 'v3.0.0' }
  s.social_media_url = 'https://twitter.com/zipleen'

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'tvheadend-ios-lib/**/*.{h,m}'
  s.public_header_files = 'tvheadend-ios-lib/**/*.h'
  s.prefix_header_file = 'tvheadend-ios-lib/tvheadend-ios-lib-Prefix.pch'
  
  s.frameworks = 'Foundation', 'SystemConfiguration', 'CFNetwork'
  s.weak_framework = 'CoreText', 'MediaAccessibility'

  s.requires_arc = true
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC -all_load' }

  s.ios.compiler_flags = '-DENABLE_XBMC'
  #s.ios.compiler_flags = '-DENABLE_CHROMECAST -DENABLE_XBMC'
  s.ios.dependency 'AFNetworking', '~> 3.1'
  #s.ios.dependency 'google-cast-sdk'

  s.tvos.dependency  'AFNetworking', '~> 3.1'

end
