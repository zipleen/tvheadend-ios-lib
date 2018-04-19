//
//  TVHStatusSubscription.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/18/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHServer.h"
#import "TVHStatusSubscription.h"

@interface TVHStatusSubscription()
@property (nonatomic, weak) TVHServer *tvhServer;
@end

@implementation TVHStatusSubscription

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    
    return self;
}

- (void)setStart:(id)startDate {
    if([startDate isKindOfClass:[NSNumber class]]) {
        _start = [NSDate dateWithTimeIntervalSince1970:[startDate intValue]];
    }
}

- (void) updateValuesFromDictionary:(NSDictionary*) values {
    [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

- (NSInteger)bandwidth
{
    if (self.in) {
        return self.in;
    }
    return self.bw;
}

- (TVHChannel*)mappedChannel {
    return [[self.tvhServer channelStore] channelWithName:self.channel];
}

- (void)killConnection {
    [[self.tvhServer.connectionStore findConnectionStartedAt:self.start withPeer:self.hostname] killConnection];
}
@end
