//
//  TVHService.m
//  TvhClient
//
//  Created by Luis Fernandes on 09/11/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHService.h"
#import "TVHServer.h"

@interface TVHService()
@property (nonatomic, weak) TVHServer *tvhServer;
@end

@implementation TVHService

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    
    return self;
}

- (void)updateValuesFromDictionary:(NSDictionary*) values {
    [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

- (void)updateValuesFromService:(TVHService*)service {
    
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

- (NSComparisonResult)compareByName:(TVHService *)otherObject {
    return [self.svcname compare:otherObject.svcname];
}

- (TVHChannel*)mappedChannel {
    return [[self.tvhServer channelStore] channelWithName:self.channelname];
}

- (NSString*)streamURL {
    if ( self.uuid ) {
        return [NSString stringWithFormat:@"%@/stream/service/%@", self.tvhServer.httpUrl, self.uuid];
    } else {
        return [NSString stringWithFormat:@"%@/stream/service/%@", self.tvhServer.httpUrl, self.id];
    }
}

- (NSString*)playlistStreamURL {
    // there is no support for playlist in service
    return nil;
}

- (NSString*)htspStreamURL {
    return nil;
}

- (BOOL)isLive {
    return YES;
}

- (TVHEpg*)currentPlayingProgram {
    if (self.mappedChannel) {
        return self.mappedChannel.currentPlayingProgram;
    }
    return nil;
}

- (NSString*)imageUrl {
    return [self.mappedChannel imageUrl];
}

- (NSString*)name {
    if (self.mappedChannel) {
        return [self.mappedChannel name];
    }
    return self.svcname;
}

- (int)number {
    return 0;
}
@end
