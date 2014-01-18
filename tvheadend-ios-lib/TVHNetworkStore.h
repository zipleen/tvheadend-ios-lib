//
//  TVHNetworkStore.h
//  tvheadend-ios-lib
//
//  Created by zipleen on 23/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHApiClient.h"

#define TVHNetworkStoreReloadNotification @"networksNotificationClassReceived"
#define TVHNetworkStoreWillLoadNotification @"willLoadNetwork"
#define TVHNetworkStoreDidLoadNotification @"didLoadNetwork"
#define TVHNetworkStoreDidErrorNotification @"didErrorNetworkStore"

@class TVHServer;
@class TVHNetwork;

@protocol TVHNetworkDelegate <NSObject>
@optional
- (void)willLoadNetwork;
- (void)didLoadNetwork;
- (void)didErrorNetworkStore:(NSError*)error;
@end

@protocol TVHNetworkStore <TVHApiClientDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) id <TVHNetworkDelegate> delegate;
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchNetworks;

- (TVHNetwork*)objectAtIndex:(NSUInteger) row;
- (int)count;
@end
