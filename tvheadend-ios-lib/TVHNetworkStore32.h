//
//  TVHNetworkStore32.h
//  tvheadend-ios-lib
//
//  Created by zipleen on 23/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHNetworkStore.h"
#import "TVHNetwork.h"

@class TVHServer;

@interface TVHNetworkStore32 : NSObject <TVHApiClientDelegate, TVHNetworkDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) id <TVHNetworkDelegate> delegate;
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchNetworks;

- (TVHNetwork*)objectAtIndex:(int) row;
- (int)count;
@end
