//
//  TVHChannelStore.h
//  TvhClient
//
//  Created by Luis Fernandes on 01/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import "TVHChannel.h"
#import "TVHApiClient.h"

#define TVHChannelStoreReloadNotification @"channelsNotificationClassReceived"
#define TVHChannelStoreWillLoadNotification @"willLoadChannels"
#define TVHChannelStoreDidLoadNotification @"didLoadChannels"
#define TVHChannelStoreDidErrorNotification @"didErrorLoadChannels"
@class TVHServer;

typedef void (^ChannelLoadedCompletionBlock)(NSArray *channels);

@protocol TVHChannelStoreDelegate <NSObject>
@optional
- (void)willLoadChannels;
- (void)didLoadChannels;
- (void)didErrorLoadingChannelStore:(NSError*)error;
@end

@protocol TVHChannelStore <TVHApiClientDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) id <TVHChannelStoreDelegate> delegate;
@property (nonatomic, strong) NSString *filterTag;
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchChannelList;
- (void)fetchChannelListWithSuccess:(ChannelLoadedCompletionBlock)successBlock failure:(ChannelLoadedCompletionBlock)failureBlock loadEpgForChannels:(BOOL)loadEpg;

- (NSUInteger)channelCount;
- (NSArray*)channels;
- (NSArray*)arrayChannels;
- (NSArray*)channelsWithTag:(NSString*)tag;
- (TVHChannel*)channelWithName:(NSString*)name;
- (TVHChannel*)channelWithId:(NSString*)channelId;
- (NSArray*)filteredChannelList;
- (void)updateChannelsProgress;
@end
