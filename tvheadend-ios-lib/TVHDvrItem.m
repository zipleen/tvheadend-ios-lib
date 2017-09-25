//
//  TVHDvrItem.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 28/02/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHDvrItem.h"
#import "TVHDvrActions.h"
#import "TVHChannelStore.h"
#import "TVHServer.h"


@implementation TVHDvrItem
@synthesize pri = _pri;
@synthesize description = _description;
@synthesize title = _title;
@synthesize end = _end;

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke `initWithTvhServer:` instead.", NSStringFromClass([self class])] userInfo:nil];
}

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    
    return self;
}

- (void)dealloc {
    self.channel = nil;
    self.chicon = nil;
    self.config_name = nil;
    self.description = nil;
    self.start = nil;
    self.end = nil;
    self.creator = nil;
    self.pri = nil;
    self.status = nil;
    self.schedstate = nil;
    self.url = nil;
    self.episode = nil;
}

- (NSString*)title
{
    if (self.disp_title) {
        return self.disp_title;
    }
    
    id title = _title;
    
    if( [title isKindOfClass:[NSDictionary class]] ) {
        return [title objectForKey:@0];
    }
    
    return title;
}

- (NSString*)description
{
    if (self.disp_description) {
        return self.disp_description;
    }
    
    id description = _description;
    
    if( [description isKindOfClass:[NSDictionary class]] ) {
        return [description objectForKey:@0];
    }
    
    return description;
}

- (void)setPri:(id)pri
{
    if( [pri isKindOfClass:[NSString class]] ) {
        _pri = pri;
    }
    
    if( [pri isKindOfClass:[NSNumber class]] ) {
        _pri = [TVH_IMPORTANCE objectForKey:[NSString stringWithFormat:@"%@", pri]];
    }
}

- (NSString*)pri
{
    if (self.tvhServer.isVersionFour) {
        return [TVH_IMPORTANCE valueForKey:_pri];
    }
    return _pri;
}

- (NSString*)fullTitle {
    NSString *episode = self.episode;
    if ( episode == nil ) {
        episode = @"";
    }
    
    return [NSString stringWithFormat:@"%@ %@", self.title, episode];
}

- (void)setStart:(id)startDate {
    if( ! [startDate isKindOfClass:[NSString class]] ) {
        _start = [NSDate dateWithTimeIntervalSince1970:[startDate intValue]];
    }
}

- (void)setEnd:(id)endDate {
    if( ! [endDate isKindOfClass:[NSString class]] ) {
        _end = [NSDate dateWithTimeIntervalSince1970:[endDate intValue]];
    }
}

- (void)setStart_real:(id)start_real {
    if( ! [start_real isKindOfClass:[NSString class]] ) {
        _start_real = [NSDate dateWithTimeIntervalSince1970:[start_real intValue]];
    }
}

- (void)setStop_real:(id)stop_real {
    if( ! [stop_real isKindOfClass:[NSString class]] ) {
        _stop_real = [NSDate dateWithTimeIntervalSince1970:[stop_real intValue]];
    }
}

- (void)updateValuesFromDictionary:(NSDictionary*) values {
    [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

- (void)deleteRecording {
    if ([self.tvhServer isVersionFour]) {
        if (self.isRecording) {
            if (self.tvhServer.apiVersion.integerValue >= 16) {
                // api version 16, or 4.1.x has STOP (whereas cancel will stop AND delete the file)
                [TVHDvrActions doAction:@"api/dvr/entry/stop" withData:@{@"uuid":self.uuid} withTvhServer:self.tvhServer];
            } else {
                // 4.0.x (max version 15) only has cancel
                [TVHDvrActions doAction:@"api/dvr/entry/cancel" withData:@{@"uuid":self.uuid} withTvhServer:self.tvhServer];
            }
        } else {
            [TVHDvrActions doIdnodeAction:@"delete" withData:@{@"uuid":self.uuid} withTvhServer:self.tvhServer];
        }
    } else {
        if ( self.isScheduledForRecording || self.isRecording ) {
            [TVHDvrActions cancelRecording:self.id withTvhServer:self.tvhServer];
        } else {
            [TVHDvrActions deleteRecording:self.id withTvhServer:self.tvhServer];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHWillRemoveEpgFromRecording
                                                            object:self];
    });
}

- (BOOL)isScheduledForRecording {
    if (self.sched_status != nil) {
        return [self.sched_status isEqualToString:@"scheduled"];
    }
    return [[self schedstate] isEqualToString:@"scheduled"];
}

- (BOOL)isRecording {
    if (self.sched_status != nil) {
        return [self.sched_status isEqualToString:@"recording"];
    }
    return [[self schedstate] isEqualToString:@"recording"];
}

- (TVHChannel*)channelObject {
    id <TVHChannelStore> store = [self.tvhServer channelStore];
    TVHChannel *channel ;
    
    if ([self.tvhServer isVersionFour]) {
        channel = [store channelWithId:self.channel];
    } else {
        channel = [store channelWithName:self.channel];
    }
    
    return channel;
}

// http://xxx:9981/dvrfile/cc9e5a804b06176a709daccc2f23c3cd
// "%@/dvrfile/%@", self.tvhServer.httpUrl, self.uuid
- (NSString*)streamURL {
    if ( self.url && ![self.url isEqualToString:@"(null)"]) {
        return [NSString stringWithFormat:@"%@/%@", self.tvhServer.httpUrl, self.url];
    }
    return nil;
}

- (NSString*)playlistStreamURL {
    return nil;
}

- (NSString*)htspStreamURL {
    return nil;
}

- (BOOL)isLive {
    return NO;
}

- (TVHEpg*)currentPlayingProgram {
    return nil;
}

- (NSString*)streamUrlWithInternalPlayer:(BOOL)internal {
    return [self.tvhServer.playStream streamUrlForObject:self withInternalPlayer:internal];
}

- (NSString*)name {
    return self.fullTitle;
}

- (NSString*)imageUrl {
    return [self.channelObject imageUrl];
}

- (NSDate*)end {
    if (_end) {
        return _end;
    }
    
    return [NSDate dateWithTimeInterval:self.duration sinceDate:self.start];
}

- (BOOL)isEqual: (id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    TVHDvrItem *otherCast = other;
    return self.id == otherCast.id;
}
@end
