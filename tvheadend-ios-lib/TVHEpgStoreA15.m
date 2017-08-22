//
//  TVHEpgStore40.m
//  TvhClient
//
//  Created by Luis Fernandes on 02/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHEpgStoreA15.h"
#import "TVHServer.h"

@interface TVHEpgStoreA15 (MyPrivateMethods)
@property (nonatomic, strong) NSArray *epgStore;
@end

@implementation TVHEpgStoreA15
@synthesize filterToChannelName = _filterToChannelName;
@synthesize filterToTagName = _filterToTagName;

- (NSString*)jsonApiFieldEntries {
    return @"entries";
}

- (NSString*)apiPath {
    return @"api/epg/events/grid";
}

- (NSString*)apiMethod {
    return @"GET";
}

- (void)setFilterToChannel:(TVHChannel *)filterToChannel {
    if ( ! [filterToChannel.channelIdKey isEqualToString:_filterToChannelName] ) {
        _filterToChannelName = filterToChannel.channelIdKey;
        [self clearEpgData];
    }
}

- (void)setFilterToTag:(TVHTag *)filterToTag {
    if ( ! [filterToTag.idKey isEqualToString:_filterToTagName] ) {
        _filterToTagName = filterToTag.idKey;
        [self clearEpgData];
    }
}

- (NSInteger)numberOfRequestedEpgItems {
    NSUInteger channelCount = self.tvhServer.channelStore.channelCount;
    
    if (channelCount > 300) {
        return 3000;
    }
    
    if (channelCount > 200) {
        return 2000;
    }
    
    if (channelCount > 100) {
        return 1000;
    }
    
    return 300;
}

@end
