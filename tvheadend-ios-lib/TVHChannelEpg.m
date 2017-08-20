//
//  TVHChannelEpg.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/11/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHChannelEpg.h"

@interface TVHChannelEpg()
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSMutableArray *channelPrograms;
@end

@implementation TVHChannelEpg

- (id)initWithDate:(NSString*)startDate {
    self = [super init];
    if (!self) return nil;
    
    self.date = startDate;
    
    return self;
}

- (NSMutableArray*)channelPrograms {
    if (!_channelPrograms) {
        _channelPrograms = [[NSMutableArray alloc] init];
    }
    return _channelPrograms;
}

- (NSArray*)programs {
    return [self.channelPrograms copy];
}

- (void)addEpg:(TVHEpg*)epg {
    @synchronized (self.channelPrograms) {
        if ( [self.channelPrograms indexOfObject:epg] == NSNotFound ) {
            [self.channelPrograms addObject:epg];
        }
    }
}

- (void)removeEpg:(TVHEpg*)epg {
    @synchronized (self.channelPrograms) {
        [self.channelPrograms removeObject:epg];
    }
}

@end
