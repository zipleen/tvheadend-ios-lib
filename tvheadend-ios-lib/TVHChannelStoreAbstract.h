//
//  TVHChannelStore.h
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/3/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/. 
//

#import "TVHChannelStore.h"
#import "TVHEpgStore.h"

@interface TVHChannelStoreAbstract : NSObject <TVHChannelStore, TVHEpgStoreDelegate, TVHApiClientDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) id <TVHChannelStoreDelegate> delegate;
@property (nonatomic, strong) NSString *filterTag;
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchChannelList;
- (void)fetchChannelListWithSuccess:(ChannelLoadedCompletionBlock)successBlock failure:(ChannelLoadedCompletionBlock)failureBlock loadEpgForChannels:(BOOL)loadEpg;

- (NSUInteger)channelCount;

// get a copy of the full channels array
- (NSArray*)channelsCopy;

// get a copy of the channels array, but if we have set filterTag it will only return the filtered tags
- (NSArray*)filteredChannelsCopy;

// get a channel array with a specific tag
- (NSArray*)channelsWithTag:(NSString*)tag;

- (TVHChannel*)channelWithName:(NSString*)name;
- (TVHChannel*)channelWithId:(NSString*)channelId;
- (void)updateChannelsProgress;
@end
