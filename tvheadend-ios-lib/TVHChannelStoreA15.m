//
//  TVHChannelStore40.m
//  TvhClient
//
//  Created by Luis Fernandes on 01/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHChannelStoreA15.h"

@interface TVHChannelStoreA15(MyPrivate)
@property (nonatomic, strong) id <TVHEpgStore> currentlyPlayingEpgStore;
- (void)signalDidLoadChannels;
@end

@implementation TVHChannelStoreA15

- (NSString*)apiPath {
    return @"api/channel/grid";
}

- (NSDictionary*)apiParameters {
    return @{@"start":@"0", @"limit":@"99999999", @"sort":@"number", @"dir":@"ASC"};
}

- (void)didLoadEpg {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // for each epg
        NSArray *list = [self.currentlyPlayingEpgStore epgStoreItems];
        for (TVHEpg *epg in list) {
            TVHChannel *channel = [self channelWithId:epg.channelUuid];
            [channel addEpg:epg];
        }
        // instead of having this delegate here, channel could send a notification and channel controller
        // could catch it and reload only that line if data was different ?
        [self signalDidLoadChannels];
    });
}

@end
