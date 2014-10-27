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

#import "TVHEpgStore40.h"
#import "TVHServer.h"

@interface TVHEpgStore40 (MyPrivateMethods)
@property (nonatomic, strong) NSArray *epgStore;
@end

@implementation TVHEpgStore40
@synthesize filterToChannelName = _filterToChannelName;

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
        self.epgStore = nil;
    }
}

@end
