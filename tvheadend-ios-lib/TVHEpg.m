//
//  TVHEpg.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/10/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHEpg.h"
#import "TVHServer.h"
#import "TVHDvrActions.h"

@interface TVHEpg()
@property (nonatomic, weak) TVHServer *tvhServer;
@end

@implementation TVHEpg
@synthesize description = _description;

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [self init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    
    return self;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    // returns TVHEpg
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willRemoveEpgFromRecording:)
                                                 name:TVHWillRemoveEpgFromRecording
                                               object:nil];
    
    // returns nsnumber
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSuccessfulyAddEpgToRecording:)
                                                 name:TVHDidSuccessfulyAddEpgToRecording
                                               object:nil];
    return self;
}

- (NSString*)channelIdKey {
    if ( self.channelUuid ) {
        return self.channelUuid;
    }
    return [NSString stringWithFormat:@"%d", (int)self.channelid];
}

// this one is wrong because I don't know if it actually removed recording or not! 
- (void)willRemoveEpgFromRecording:(NSNotification *)notification {
    if ([[notification name] isEqualToString:TVHWillRemoveEpgFromRecording]) {
        TVHDvrItem *dvritem = [notification object];
        if ( [dvritem.channel isEqualToString:self.channel] && [dvritem.title isEqualToString:self.title] && [dvritem.start isEqual:self.start] ) {
            self.schedstate = nil;
            
            // update channels
            [[self.tvhServer channelStore] updateChannelsProgress];
            // update channel program detail view
            TVHChannel *ch = [[self.tvhServer channelStore] channelWithId:self.channelIdKey];
            [ch signalDidLoadEpgChannel];
        }
    }
}

- (void)didSuccessfulyAddEpgToRecording:(NSNotification *)notification {
    if ([[notification name] isEqualToString:TVHDidSuccessfulyAddEpgToRecording]) {
        NSNumber *number = [notification object];
        if ( [number intValue] == self.id || [number intValue] == self.eventId ) {
            // not exactly right, but it's better than having to get ALL the epg again :p
            if ( [self progress] > 0 ) {
                self.schedstate = @"recording";
            } else {
                self.schedstate = @"scheduled";
            }
        
            // update channels
            [[self.tvhServer channelStore] updateChannelsProgress];
            // update channel program detail view
            TVHChannel *ch = [[self.tvhServer channelStore] channelWithId:self.channelIdKey];
            [ch signalDidLoadEpgChannel];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.channel = nil;
    self.chicon = nil;
    self.title = nil;
    self.subtitle = nil;
    self.episode = nil;
    self.start = nil;
    self.end = nil;
    self.schedstate = nil;
    self.contenttype = nil;
}

- (NSString*)chicon {
    // try to fetch picture from channel
    return [self.channelObject imageUrl];
}

- (NSString*)fullTitle {
    /*
    NSString *subtitle = self.subtitle;
    if ( subtitle == nil ) {
        subtitle = @"";
    }
    */
    NSString *episode = self.episode;
    if ( episode == nil ) {
        episode = @"";
    }
    
    return [NSString stringWithFormat:@"%@ %@", self.title, episode];
}

- (void)setStart:(id)startDate {
    if([startDate isKindOfClass:[NSNumber class]]) {
        _start = [NSDate dateWithTimeIntervalSince1970:[startDate intValue]];
    }
}

- (void)setEnd:(id)endDate {
    if([endDate isKindOfClass:[NSNumber class]]) {
        _end = [NSDate dateWithTimeIntervalSince1970:[endDate intValue]];
    }
}

- (void)updateValuesFromDictionary:(NSDictionary*) values {
    [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

- (NSComparisonResult)compareByTime:(TVHEpg *)otherObject {
    return [self.start compare:otherObject.start];
}

- (BOOL)inProgress {
    if ( self.progress > 0 && self.progress < 1 ) {
        return YES;
    }
    return NO;
}

- (float)progress {
    NSDate *now = [NSDate date];
    NSTimeInterval actualLength = [now timeIntervalSinceDate:self.start];
    NSTimeInterval programLength = [self.end timeIntervalSinceDate:self.start];
    
    if( [now compare:self.start] == NSOrderedAscending ) {
#ifdef TESTING
        //NSLog(@"start(0) for %@ is %@", self.title, self.start);
#endif
        return 0;
    }
    if( [now compare:self.end] == NSOrderedDescending ) {
#ifdef TESTING
        //NSLog(@"start(1) for %@ is %@", self.title, self.start);
#endif
        return 1;
    }
    return actualLength / programLength;
}

- (void)addRecording {
    NSInteger idnum = self.id;
    if ([self.tvhServer isVersionFour]) {
        idnum = self.eventId;
    }
    [TVHDvrActions addRecording:idnum withConfigName:nil withTvhServer:self.tvhServer];
}

- (BOOL)isEqual: (id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    TVHEpg *otherCast = other;
    if (self.id == 0) {
        if (self.eventId == otherCast.eventId) {
            return YES;
        }
        return NO;
    }
    
    if (self.id == otherCast.id) {
        return YES;
    }
    return NO;
}

- (TVHChannel*)channelObject {
    id <TVHChannelStore> store = [self.tvhServer channelStore];
    TVHChannel *channel = [store channelWithId:self.channelIdKey];
    return channel;
}

- (void)addAutoRec {
    if ([[self.tvhServer apiVersion] intValue]> 14) {
        NSDictionary *sendProperties = @{@"enabled":@1,@"comment":@"Created from TvhClient",@"title":self.title,@"channel":self.channelUuid};
        NSString *data = [TVHDvrActions jsonArrayString:sendProperties];
        [TVHDvrActions doAction:@"api/dvr/autorec/create" withData:@{@"conf":data} withTvhServer:self.tvhServer];
        return ;
    }
    
    [TVHDvrActions addAutoRecording:self.id withConfigName:nil withTvhServer:self.tvhServer];
}

- (BOOL)isScheduledForRecording {
    if (self.dvrState) {
        return [self.dvrState isEqualToString:@"scheduled"];
    }
    return [[self schedstate] isEqualToString:@"scheduled"];
}

- (BOOL)isRecording {
    if (self.dvrState) {
        return [self.dvrState isEqualToString:@"recording"];
    }
    return [[self schedstate] isEqualToString:@"recording"];
}

// 4.0
- (void)setStop:(id)stopDate {
    if([stopDate isKindOfClass:[NSNumber class]]) {
        _stop = [NSDate dateWithTimeIntervalSince1970:[stopDate intValue]];
        _end = [NSDate dateWithTimeIntervalSince1970:[stopDate intValue]];
    }
}

- (void)setSummary:(NSString *)summary {
    _summary = summary;
    _description = summary;
}

- (NSInteger)duration
{
    if (_duration && _duration > 0) {
        return _duration;
    }
    
    return [self.end timeIntervalSinceDate:self.start];
}

@end
