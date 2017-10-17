//
//  TVHNetworkStore40.h
//  tvheadend-ios-lib
//
//  Created by zipleen on 23/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHNetworkStore.h"
#import "TVHNetwork.h"

@class TVHServer;

@interface TVHNetworkStoreA15 : NSObject <TVHApiClientDelegate, TVHNetworkDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) id <TVHNetworkDelegate> delegate;
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchNetworks;

- (NSArray*)networksCopy;
@end
