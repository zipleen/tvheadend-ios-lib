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

- (id)copyWithZone:(NSZone *)zone {
    TVHDvrItem *item = [[[self class] allocWithZone:zone] initWithTvhServer:self.tvhServer];    
    item.channel = self.channel;
    item.chicon = self.chicon;
    item.config_name = self.config_name;
    item.title = self.title;
    item.description = self.description;
    item.id = self.id;
    item.start = self.start;
    item.stop = self.stop;
    item.duration = self.duration;
    item.creator = self.creator;
    item.pri = self.pri;
    item.status = self.status;
    item.schedstate = self.schedstate;
    item.filesize = self.filesize;
    item.url = self.url;
    item.dvrType = self.dvrType;
    item.episode = self.episode;
    
    item.uuid = self.uuid;
    item.disp_title = self.disp_title;
    item.disp_description = self.disp_description;
    item.disp_subtitle = self.disp_subtitle;
    item.sched_status = self.sched_status;
    item.errorcode = self.errorcode;
    item.errors = self.errors;
    item.filename = self.filename;
    item.start_real = self.start_real;
    item.stop_real = self.stop_real;
    
    return item;
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

/*
 * disp_title | title (disp_subtitle | subtitle - episode)
 */
- (NSString*)fullTitle {
    NSString *parenthesis = self.episode;
    if ( parenthesis != nil && ![parenthesis isEqualToString:@""] ) {
        parenthesis = self.episode;
    }
    
    // disp_subtitle cannot be shown in the UK because it has the full description copied into it!
    
    if (parenthesis != nil && ![parenthesis isEqualToString:@""]) {
        parenthesis = [NSString stringWithFormat:@" (%@)", parenthesis];
    } else {
        parenthesis = @"";
    }
    
    NSString *title = self.disp_title;
    if (title == nil || [title isEqualToString:@""]) {
        title = self.title;
    }
    
    return [NSString stringWithFormat:@"%@%@", title, parenthesis];
}

- (void)setStart:(id)startDate {
    if( [startDate isKindOfClass:[NSDate class]] ) {
        _start = startDate;
        return;
    }
    
    if( ! [startDate isKindOfClass:[NSString class]] ) {
        _start = [NSDate dateWithTimeIntervalSince1970:[startDate intValue]];
    }
}

- (void)setEnd:(id)endDate {
    if( [endDate isKindOfClass:[NSDate class]] ) {
        _end = endDate;
        return;
    }
    
    if( ! [endDate isKindOfClass:[NSString class]] ) {
        _end = [NSDate dateWithTimeIntervalSince1970:[endDate intValue]];
    }
}

- (void)setStop:(id)endDate {
    if( [endDate isKindOfClass:[NSDate class]] ) {
        _stop = endDate;
        [self setEnd:endDate];
        return;
    }
    
    if( ! [endDate isKindOfClass:[NSString class]] ) {
        _stop = [NSDate dateWithTimeIntervalSince1970:[endDate intValue]];
        [self setEnd:endDate];
    }
}

- (void)setStart_real:(id)start_real {
    if( [start_real isKindOfClass:[NSDate class]] ) {
        _start_real = start_real;
        return;
    }
    
    if( ! [start_real isKindOfClass:[NSString class]] ) {
        _start_real = [NSDate dateWithTimeIntervalSince1970:[start_real intValue]];
    }
}

- (void)setStop_real:(id)stop_real {
    if( [stop_real isKindOfClass:[NSDate class]] ) {
        _stop_real = stop_real;
        return;
    }
    
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

- (BOOL)updateRecording {
    if (!([self.start compare:self.stop] == NSOrderedAscending)) {
        return false;
    }
    
    if (self.channel == nil || [self.channel isEqualToString:@""]) {
        return false;
    }
    
    // create the properties
    NSMutableDictionary *updatedProperties = [NSMutableDictionary new];
    [updatedProperties setValue:self.disp_title forKey:@"disp_title"];
    [updatedProperties setValue:[NSString stringWithFormat:@"%.0f", self.start.timeIntervalSince1970] forKey:@"start"];
    [updatedProperties setValue:[NSNumber numberWithInteger:self.start_extra] forKey:@"start_extra"];
    [updatedProperties setValue:[NSString stringWithFormat:@"%.0f", self.stop.timeIntervalSince1970] forKey:@"stop"];
    [updatedProperties setValue:[NSNumber numberWithInteger:self.stop_extra] forKey:@"stop_extra"];
    [updatedProperties setValue:self.channel forKey:@"channel"];
    [updatedProperties setValue:self.config_name forKey:@"config_name"];
    [updatedProperties setValue:self.comment forKey:@"comment"];
    
    
    
    if (self.uuid) {
        // update
        [updatedProperties setValue:self.uuid forKey:@"uuid"];
        // wtf people, it's a JSON encoded string in a form-url http request that says node:JSON_STRING !
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[updatedProperties copy]
                                                           options:0
                                                             error:nil];
        if (jsonData == nil) {
            return false;
        }
        NSString *jsonConvertedProperties = [NSString stringWithUTF8String:[jsonData bytes]];
        if (jsonConvertedProperties == nil) {
            return false;
        }
        [TVHDvrActions doIdnodeAction:@"save" withData:@{@"node":jsonConvertedProperties} withTvhServer:self.tvhServer];
    } else {
        // create
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[updatedProperties copy]
                                                           options:0
                                                             error:nil];
        if (jsonData == nil) {
            return false;
        }
        NSString *jsonConvertedProperties = [NSString stringWithUTF8String:[jsonData bytes]];
        if (jsonConvertedProperties == nil) {
            return false;
        }
        [TVHDvrActions doAction:@"api/dvr/entry/create" withData:@{@"conf":jsonConvertedProperties} withTvhServer:self.tvhServer];
    }
    
    return true;
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

- (NSString*)channelIdKey {
    return self.channelObject.channelIdKey;
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

- (NSString*)name {
    return self.fullTitle;
}

- (NSString*)imageUrl {
    return self.channelObject.imageUrl;
}

- (int)number {
    return self.channelObject.number;
}

- (NSDate*)end {
    if (_end) {
        return _end;
    }
    
    if (_stop) {
        return _stop;
    }
    
    return [NSDate dateWithTimeInterval:self.duration sinceDate:self.start];
}

- (NSComparisonResult)compareByDateAscending:(TVHDvrItem *)otherObject {
    return [self.start compare:otherObject.start];
}

- (NSComparisonResult)compareByDateDescending:(TVHDvrItem *)otherObject {
    return [self.start compare:otherObject.start] * -1;
}

- (BOOL)isEqual: (id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    
    TVHDvrItem *otherCast = other;
    if (self.uuid != nil) {
        return [self.uuid isEqualToString:otherCast.uuid];
    }
    
    return self.id == otherCast.id;
}
@end
