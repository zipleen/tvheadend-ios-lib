//
//  TVHAutoRecItem.m
//  TvhClient
//
//  Created by Luis Fernandes on 3/14/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHAutoRecItem.h"
#import "TVHTableMgrActions.h"
#import "TVHDvrActions.h"
#import "TVHServer.h"

@interface TVHAutoRecItem ()
@property (nonatomic, weak) TVHJsonClient *jsonClient;
@property (nonatomic, strong) NSMutableArray *updatedProperties;
@end

@implementation TVHAutoRecItem
@synthesize pri = _pri;

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.jsonClient = [self.tvhServer jsonClient];
    
    return self;
}

- (NSMutableArray*)updatedProperties {
    if ( ! _updatedProperties ) {
        _updatedProperties = [[NSMutableArray alloc] init];
    }
    return _updatedProperties;
}

- (id)copyWithZone:(NSZone *)zone {
    TVHAutoRecItem *item = [[[self class] allocWithZone:zone] init];
    item.channel = self.channel;
    item.comment = self.comment;
    item.contenttype = self.contenttype;
    item.config_name = self.config_name;
    item.approx_time = self.approx_time;
    item.enabled = self.enabled;
    item.id = self.id;
    item.creator = self.creator;
    item.pri = self.pri;
    item.title = self.title;
    item.tag = self.tag;
    item.weekdays = self.weekdays;
    item.genre = self.genre;
    item.jsonClient = self.jsonClient;
    item.uuid = self.uuid;
    return item;
}

- (void)setWeekdays:(id)weekdays {
    if([weekdays isKindOfClass:[NSString class]]) {
        _weekdays = [weekdays componentsSeparatedByString:@","];
    }
    if([weekdays isKindOfClass:[NSArray class]]) {
        _weekdays = weekdays;
    }
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

- (void)updateValue:(id)value forKey:(NSString*)key {
    [self setValue:value forKey:key];
    [self.updatedProperties addObject:key];
}

- (void)updateValuesFromDictionary:(NSDictionary*) values {
    [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

+ (NSString*)stringFromMinutes:(int)dayMinutes {
    return [NSString stringWithFormat:@"%d:%02d", (int)(dayMinutes/60), (int)(dayMinutes%60) ];
}

- (NSString*)stringFromAproxTime {
    if ( self.approx_time == 0 ) {
        return nil;
    }
    return [TVHAutoRecItem stringFromMinutes:(int)self.approx_time];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

- (void)deleteAutoRec {
    if ([self.tvhServer isVersionFour]) {
        return [TVHDvrActions doIdnodeAction:@"delete" withData:@{@"uuid":self.uuid} withTvhServer:self.tvhServer];
    }
    // TODO: fix this self.id thing
    [TVHTableMgrActions doTableMgrAction:@"delete" withJsonClient:self.jsonClient inTable:@"autorec" withEntries:[NSString stringWithFormat:@"%d", (int)self.id] ];
}

- (void)updateAutoRec {
    if ( [self.updatedProperties count] == 0 ) {
        return;
    }
    
    NSMutableDictionary *sendProperties = [[NSMutableDictionary alloc] init];
    for (NSString* key in self.updatedProperties) {
        [sendProperties setValue:[self valueForKey:key] forKey:key];
    }
    
    if ([self.tvhServer isVersionFour]) {
        [sendProperties setValue:self.uuid forKey:@"uuid"];
        
        return [TVHDvrActions doIdnodeAction:@"save" withData:@{@"node":[TVHDvrActions jsonArrayString:@[sendProperties]]} withTvhServer:self.tvhServer];
    }
    
    [sendProperties setValue:[NSString stringWithFormat:@"%d", (int)self.id] forKey:@"id"];
    [TVHTableMgrActions doTableMgrAction:@"update" withJsonClient:self.jsonClient inTable:@"autorec" withEntries:sendProperties ];
}

- (TVHChannel*)channelObject
{
    TVHChannel *channel;
    id <TVHChannelStore> channelStore = [self.tvhServer channelStore];
    if ( [self.tvhServer.version integerValue] < 39 ) {
        channel = [channelStore channelWithName:self.channel];
    } else {
        channel = [channelStore channelWithId:self.channel];
    }
    return channel;
}
@end
