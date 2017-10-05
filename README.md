TVHeadend iOS Library 
=======================

This library is a split from the model / network code from TvhClient. The code is now independent of the application, which means it can be used in other apps. Right now this is used for both the iOS and tvOS versions of TvhClient. 

TvhClient is now dependent on this library. 

TvhClient is a TVHeadend iOS (iPhone, iPad) Client app, which allows you to remote control the TVHeadend server  ( https://github.com/tvheadend/tvheadend ) - a DVB receiver, DVR and streaming server.

## Getting the code with Cocoapods

Install tvhclient-lib using cocoapods, add this to your Podfile (and change the whatever is the latest tag version)

    pod 'tvhclient-lib', :git => 'https://github.com/zipleen/tvheadend-ios-lib.git', tag: 'v3.0.0'

Or try to use the latest version from the pod repository, if it ever gets there =)

If you want to develop this library within your own app, you can try also using:
  
    pod 'tvhclient-lib', :path => 'tvheadend-ios-lib/'

## Getting the code

    git clone git://github.com/zipleen/tvheadend-ios-lib.git
    cd tvheadend-ios-lib
    pod install

CocoaPods is required to install the dependencies and develop the library. 

Build and run ! Send your patches to me via a pull request ;)

## License

This app's source code is licensed under the Mozilla Public License 2 (MPL-2). 


