//
//  TVHChannel.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/3/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHChannel.h"
#import "TVHEpgStore.h"
#import "TVHChannelEpg.h"
#import "TVHServer.h"
#import "NSArray+Utils.h"

@interface TVHChannel() <TVHEpgStoreDelegate> {
    NSDateFormatter *dateFormatter;
}
@property (nonatomic, strong) NSMutableArray *channelEpgDataByDay;
@property (nonatomic, strong) id <TVHEpgStore> restOfEpgStore;
@property (strong, nonatomic) NSCache *tvhImageCache;
@end

@implementation TVHChannel

- (void)dealloc {
    self.name = nil;
    self.detail = nil;
    self.imageUrl = nil;
    self.image = nil;
    self.tags = nil;
    self.channelEpgDataByDay = nil;
    self.restOfEpgStore = nil;
    dateFormatter = nil;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[TVHChannel alloc] init];
    
    if (copy) {
        [copy setTvhServer:self.tvhServer];
        [copy setDelegate:self.delegate];
        [copy setName:[self.name copyWithZone:zone]];
        [copy setDetail:[self.detail copyWithZone:zone]];
        [copy setImageUrl:[self.imageUrl copyWithZone:zone]];
        [copy setCh_icon:[self.ch_icon copyWithZone:zone]];
        [copy setChicon:[self.chicon copyWithZone:zone]];
        [copy setNumber:self.number];
        [copy setImage:[self.image copyWithZone:zone]];
        [copy setChid:self.chid];
        [copy setTags:[self.tags copyWithZone:zone]];
        [copy setServices:[self.services copyWithZone:zone]];
        [copy setEpg_pre_start:self.epg_pre_start];
        [copy setEpg_post_end:self.epg_post_end];
        [copy setEpggrabsrc:[self.epggrabsrc copyWithZone:zone]];
        [copy setUuid:[self.uuid copyWithZone:zone]];
        [copy setIcon:[self.icon copyWithZone:zone]];
        [copy setIcon_public_url:[self.icon_public_url copyWithZone:zone]];
        [copy setChannelEpgDataByDay:[self.channelEpgDataByDay copyWithZone:zone]];
        [copy setRestOfEpgStore:self.restOfEpgStore];
    }
    
    return copy;
}

- (id <TVHEpgStore>)restOfEpgStore {
    if ( ! _restOfEpgStore ) {
        _restOfEpgStore = [self.tvhServer createEpgStoreWithName:@"ChannelEPG"];
        [_restOfEpgStore setDelegate:self];
        [_restOfEpgStore setFilterToChannel:self];
    }
    return _restOfEpgStore;
}

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;

    return self;
}

- (NSMutableArray*)channelEpgDataByDay{
    if(!_channelEpgDataByDay) {
        _channelEpgDataByDay = [[NSMutableArray alloc] init];
    }
    return _channelEpgDataByDay;
}

- (NSString*)channelIdKey {
    if ( self.uuid ) {
        return self.uuid;
    }
    return [NSString stringWithFormat:@"%d", (int)self.chid];
}

- (NSString*)imageUrl {
    // 4.0 uses icon_public_url
    if ( self.icon_public_url ) {
        if ( [self.icon_public_url isEqualToString:self.icon] ) {
            return self.icon;
        } else {
            return [NSString stringWithFormat:@"%@/%@", [self.tvhServer httpUrl], self.icon_public_url];
        }
    }
    
    // old 3.9 didn't have icon_public_url - this can be deleted in a few months
    if ( self.icon ) {
        return self.icon;
    }
    
    // < 3.5 icon
    if ( self.chicon ) {
        if ( [self.chicon isEqualToString:self.ch_icon] ) {
            return self.chicon;
        } else {
            // if they are NOT the same it means it's a image cache and we need to add server url
            return [NSString stringWithFormat:@"%@/%@", [self.tvhServer httpUrl], self.chicon];
        }
    }
    return self.ch_icon;
}

// notice that setTags has (id) instead of NSArray*, which means we can test for a NSString and convert it !
- (void)setTags:(id)tags {
    if([tags isKindOfClass:[NSString class]]) {
        _tags = [tags componentsSeparatedByString:@","];
    }
    if([tags isKindOfClass:[NSArray class]]) {
        _tags = [tags convertObjectsToStrings];
    }
}

// services only exists in 4.0
- (void)setServices:(id)services {
    if([services isKindOfClass:[NSArray class]]) {
        _services = services;
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

- (BOOL)hasTag:(NSString*)tag {
    return [self.tags containsObject:tag];
}

- (NSString*)streamURL {
    if ( [self.tvhServer isVersionFour] ) {
        return [NSString stringWithFormat:@"%@/stream/channel/%@", self.tvhServer.httpUrl, self.channelIdKey];
    }
    return [NSString stringWithFormat:@"%@/stream/channelid/%@", self.tvhServer.httpUrl, self.channelIdKey];
}

- (NSString*)playlistStreamURL {
    if ( [self.tvhServer isVersionFour] ) {
        return [NSString stringWithFormat:@"%@/playlist/channel/%@", self.tvhServer.httpUrl, self.channelIdKey];
    }
    return [NSString stringWithFormat:@"%@/playlist/channelid/%@", self.tvhServer.httpUrl, self.channelIdKey];
}

- (NSString*)htspStreamURL {
    if ( self.uuid ) {
        const char *szHexString = [self.uuid cStringUsingEncoding:NSUTF8StringEncoding];
        size_t size = strlen( szHexString ) / 2;
        if ( size > 0 ) {
            unsigned char *pBinary = calloc(size, 1);
            const char *p = &szHexString[0];
            
            for( int i = 0; i < size; i++, p += 2 ){
                sscanf( p, "%2hhx", &pBinary[i] );
            }
            
            uint32_t u32;
            memcpy(&u32, pBinary, sizeof(u32));
            u32 = u32 & 0x7FFFFFFF;
            return [NSString stringWithFormat:@"%@/tags/0/%u.ts", self.tvhServer.htspUrl, u32];
        } else {
            return nil;
        }
    }
    return [NSString stringWithFormat:@"%@/tags/0/%@.ts", self.tvhServer.htspUrl, self.channelIdKey];
}

- (BOOL)isLive {
    return YES;
}

- (NSString*)streamUrlWithTranscoding:(BOOL)transcoding withInternal:(BOOL)internal
{
    return [self.tvhServer.playStream streamUrlForObject:self withTranscoding:transcoding withInternal:internal];
}

- (TVHChannelEpg*)getChannelEpgDataByDayString:(NSString*)dateString {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@", dateString];
    NSArray *filteredArray = [self.channelEpgDataByDay filteredArrayUsingPredicate:predicate];
    if ([filteredArray count] > 0) {
        return [filteredArray objectAtIndex:0];
    } else {
        TVHChannelEpg *tvh = [[TVHChannelEpg alloc] init];
        [tvh setDate:dateString];
        [self.channelEpgDataByDay addObject:tvh];
        return tvh;
    }
}

- (void)addEpg:(TVHEpg*)epg {
    if( !dateFormatter ) {
        dateFormatter = [NSDateFormatter dateFormatterMMddyy];
    }
    
    NSString *dateString = [dateFormatter stringFromDate:epg.start];    
    TVHChannelEpg *tvhepg = [self getChannelEpgDataByDayString:dateString];
    
    // don't add duplicate epg - need to search in the array!
    if ( [tvhepg.programs indexOfObject:epg] == NSNotFound ) {
        [tvhepg.programs addObject:epg];
    }
}

- (TVHEpg*)currentPlayingProgram {
    if ( [self.channelEpgDataByDay count] == 0 ) {
#ifdef TESTING
        NSLog(@"No EPG data on array for %@", self.name);
#endif
        return nil;
    }
    
    for ( TVHChannelEpg *epgByDay in self.channelEpgDataByDay ) {
        for ( TVHEpg *epg in [epgByDay programs] ) {
            if ( [epg progress] > 0 && [epg progress] < 1 ) {
                return epg;
            }
#ifdef TESTING
            else {
                //NSLog(@"progress for %@ : %f", epg.title, [epg progress]);
            }
#endif
        }
    }
#ifdef TESTING
    NSLog(@"Didn't find any EPG for %@", self.name);
#endif
    return nil;
}

- (NSArray*)nextPrograms:(int)numberOfNextPrograms {
    int i = 0;
    NSMutableArray *nextPrograms = [[NSMutableArray alloc] init];
    if ( [self.channelEpgDataByDay count] == 0 ) {
#ifdef TESTING
        NSLog(@"No EPG data on array for %@", self.name);
#endif
        return nil;
    }
    
    for ( TVHChannelEpg *epgByDay in self.channelEpgDataByDay ) {
        for ( TVHEpg *epg in [epgByDay programs] ) {
            if ( i > 0 || (i == 0 && [epg inProgress]) ) {
                [nextPrograms addObject:epg];
                i++;
                if ( i >= numberOfNextPrograms ) {
                    break;
                }
            }
        }
        if ( i >= numberOfNextPrograms ) {
            break;
        }
    }
    return [nextPrograms copy];

}

- (NSString*)description
{
    TVHEpg *current = self.currentPlayingProgram;
    if (current) {
        return [NSString stringWithFormat:@"%@ - %@", current.title, current.description];
    }
    return nil;
}

- (NSComparisonResult)compareByName:(TVHChannel *)otherObject {
    return [self.name compare:otherObject.name];
}

- (NSComparisonResult)compareByNumber:(TVHChannel *)otherObject {
    
    if(self.number == otherObject.number) {
        return NSOrderedSame;
    } else if(self.number == 0)  //Channels without number should be placed last - treat number 0 as infinity
    {
        return NSOrderedDescending;
    } else if(otherObject.number == 0) {
        return NSOrderedAscending;
    }
    
    return self.number < otherObject.number ? NSOrderedAscending : NSOrderedDescending;
}

- (void)resetChannelEpgStore {
    self.channelEpgDataByDay = nil;
}

- (NSInteger)countEpg {
    NSInteger count = 0;
    TVHChannelEpg *epg;
    NSEnumerator *e = [self.channelEpgDataByDay objectEnumerator];
    while( epg = [e nextObject]) {
        count += [epg.programs count];
    }
    return count;
}

- (void)downloadRestOfEpg {
    [self signalWillLoadEpgChannel];
    // spawn a new epgList so we can set a filter to the channel
    [self.restOfEpgStore downloadAllEpgItems];
}

#pragma Table Call Methods

- (NSArray*)programsForDay:(NSInteger)day {
    if ( [self.channelEpgDataByDay count] == 0 ) {
        return nil;
    }
    
    if ( day < [self.channelEpgDataByDay count] ) {
        return [[self.channelEpgDataByDay[day] programs] copy];
    } else {
        NSLog(@"TVHChannel - asked for invalid day (%ld)", (long)day);
        return nil;
    }
    //NSArray *ordered = [self.channelEpgDataByDay sortedArrayUsingSelector:@selector(compareByTime:)];
}

- (TVHEpg*)programDetailForDay:(NSInteger)day index:(NSInteger)program {
    if ( day < [self.channelEpgDataByDay count] ) {
        if ( program < [[[self.channelEpgDataByDay objectAtIndex:day] programs] count] ){
            return [[[self.channelEpgDataByDay objectAtIndex:day] programs] objectAtIndex:program];
        }
    }
    return nil;
}

- (NSInteger)totalCountOfDaysEpg {
    return [self.channelEpgDataByDay count];
}

// returns the date for the first epg entry in that day
- (NSDate*)dateForDay:(NSInteger)day {
    if ( day < [self.channelEpgDataByDay count] ) {
        TVHChannelEpg *epg = [self.channelEpgDataByDay objectAtIndex:day];
        if ( epg ) {
            TVHEpg *realEpg = [epg.programs objectAtIndex:0];
            return [realEpg start];
        }
    }
    return nil;
}

- (NSInteger)numberOfProgramsInDay:(NSInteger)section{
    if ( [self.channelEpgDataByDay count] > section ) {
        return [[[self.channelEpgDataByDay objectAtIndex:section] programs] count];
    }
    return 0;
}

- (BOOL)isEqual: (id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    TVHChannel *otherCast = other;
    return self.channelIdKey == otherCast.channelIdKey;
}

- (NSUInteger)hash {
    return [self.channelIdKey hash];
}

// TODO refactor the whole ChannelEPG crap - it should be a self contained day/program store!
- (void)removeOldProgramsFromStore {
    if ( self.channelEpgDataByDay ) {
        NSArray *testingChannelEpgDataByDay = [self.channelEpgDataByDay copy];
        for ( TVHChannelEpg *channelEpg in testingChannelEpgDataByDay ) {
            NSArray *testingPrograms = [channelEpg.programs copy];
            for ( TVHEpg *obj in testingPrograms ) {
                if ( [obj progress] >= 1.0 ) {
                    // to remove the channel, we need to fetch the original channelEpg array
                    TVHChannelEpg *originalPrograms = [self.channelEpgDataByDay objectAtIndex:[self.channelEpgDataByDay indexOfObject:channelEpg]];
                    [originalPrograms.programs removeObject:obj];
                }
            }
            
            // we now need to remove days that no longer have epgs in them!
            if ( [channelEpg.programs count] == 0 ) {
                [self.channelEpgDataByDay removeObject:channelEpg];
            }
        }
    }
    
    // we need to make the controller update the channel progress - TODO how can I make this more efficient?
    [self signalDidLoadEpgChannel];
}

- (BOOL)isLastEpgFromThePast {
    TVHChannelEpg *lastChannelEpg = [self.channelEpgDataByDay lastObject];
    if ( ! lastChannelEpg ) {
        return NO; // probably we don't have an EPG! let's not trigger a refresh because of that
    }
    TVHEpg *last = [lastChannelEpg.programs lastObject];
    if ( ! last ) {
        return YES;
    }
    return ( [last.end compare:[NSDate date]] == NSOrderedAscending );
}

#pragma TVHEpgStore delegate
- (void)didLoadEpg {
    NSArray *epgItems = [self.restOfEpgStore epgStoreItems];
    for (TVHEpg *epg in epgItems) {
        [self addEpg:epg];
    }
    [self signalDidLoadEpgChannel];
}

- (void)didErrorLoadingEpgStore:(NSError*)error {
    [self signalDidErrorLoadingEpgChannel:error];
}

- (void)setDelegate:(id <TVHChannelDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

- (void)signalWillLoadEpgChannel {
    if ([self.delegate respondsToSelector:@selector(willLoadEpgChannel)]) {
        [self.delegate willLoadEpgChannel];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TVHChannelWillLoadEpgFromItself
                                                        object:self];
}

- (void)signalDidLoadEpgChannel {
    if ([self.delegate respondsToSelector:@selector(didLoadEpgChannel)]) {
        [self.delegate didLoadEpgChannel];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TVHChannelDidLoadEpgFromItself
                                                        object:self];
}

- (void)signalDidErrorLoadingEpgChannel:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(didErrorLoadingEpgChannel:)]) {
        [self.delegate didErrorLoadingEpgChannel:error];
    }
}

#pragma mark UIImage internal cache!

- (NSCache*)tvhImageCache {
    if (_tvhImageCache == nil) {
        _tvhImageCache = [[NSCache alloc] init];
    }
    return _tvhImageCache;
}

- (void)saveCache:(UIImage*)image withWidth:(int)width andHeight:(int)height {
    [self.tvhImageCache setObject:image forKey:[NSString stringWithFormat:@"%d_%d", width, height]];
}

- (UIImage*)imageFromCacheWithWidth:(int)width andHeight:(int)height {
    return [self.tvhImageCache objectForKey:[NSString stringWithFormat:@"%d_%d", width, height]];
}
@end
