use_frameworks!

pod 'AFNetworking', '~> 4.0'

target 'tvheadend-ios-lib' do
   platform :ios, '15.0'

   #pod 'google-cast-sdk'
   
   target 'tvheadend-ios-libTests' do
       inherit! :search_paths
       
pod 'AFNetworking', '~> 4.0'
       pod 'Specta'
       pod 'Expecta'
       pod 'OHHTTPStubs', '~> 8.0'
   end
end



target 'tvheadend-tvOS-lib' do
  platform :tvos, '15.0'

    target 'tvheadend-tvOS-libTests' do
        inherit! :search_paths
        
pod 'AFNetworking', '~> 4.0'
        pod 'Specta'
        pod 'Expecta'
        pod 'OHHTTPStubs', '~> 8.0'
    end
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
    end
  end
end
