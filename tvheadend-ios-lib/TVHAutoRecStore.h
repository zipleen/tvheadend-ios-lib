//
//  TVHAutoRecStore.h
//  TvhClient
//
//  Created by zipleen on 11/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHAutoRecItem.h"
#import "TVHApiClient.h"

#define TVHAutoStoreReloadNotification @"autorecNotificationClassReceived"
#define TVHAutoRecStoreWillLoadNotification @"willLoadDvrAutoRec"
#define TVHAutoRecStoreDidLoadNotification @"didLoadDvrAutoRec"
#define TVHAutoRecStoreDidErrorNotification @"didErrorDvrAutoStore"

@class TVHServer;

@protocol TVHAutoRecStoreDelegate <NSObject>
@optional
- (void)willLoadDvrAutoRec;
- (void)didLoadDvrAutoRec;
- (void)didErrorDvrAutoStore:(NSError*)error;
@end

@protocol TVHAutoRecStore <TVHApiClientDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) id <TVHAutoRecStoreDelegate> delegate;
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchDvrAutoRec;

- (TVHAutoRecItem *)objectAtIndex:(NSUInteger)row;
- (int)count;
@end

