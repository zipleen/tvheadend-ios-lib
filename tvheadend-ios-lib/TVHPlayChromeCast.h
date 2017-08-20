//
//  TVHPlayChromeCast.h
//  tvheadend-ios-lib
//
//  Created by zipleen on 07/09/14.
//  Copyright (c) 2014 zipleen. All rights reserved.
//

#ifdef ENABLE_CHROMECAST


#import "TVHPlayStreamDelegate.h"
#import <GoogleCast/GoogleCast.h>
#import "TVHModelAnalyticsProtocol.h"

@interface TVHPlayChromeCast : NSObject <GCKDeviceScannerListener,
                                        GCKDeviceManagerDelegate,
                                        GCKMediaControlChannelDelegate>
+ (TVHPlayChromeCast*)sharedInstance;
- (NSArray*)availableServers;
- (BOOL)playStream:(NSString*)xbmcName forObject:(id<TVHPlayStreamDelegate>)streamObject withTranscoding:(BOOL)transcoding withAnalytics:(id<TVHModelAnalyticsProtocol>)analytics;
@end

#endif
