//
//  TVHEpgStore.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/10/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHEpgStoreAbstract.h"
#import "TVHEpgStore.h"
#import "TVHEpg.h"
#import "TVHServer.h"

@interface TVHEpgStoreAbstract() {
    NSLock *epgUpdateInProgress;
}
@property (nonatomic, strong) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *epgStore;
@property (nonatomic, weak) id <TVHEpgStoreDelegate> delegate;
@property (nonatomic) NSInteger totalEventCount;
@property (nonatomic, strong) NSMutableDictionary *epgByChannel;
@property (nonatomic) NSUInteger lastStart;
@property (nonatomic, strong) NSDate *lastStartDate;
@end

@implementation TVHEpgStoreAbstract

- (void)appWillEnterForeground:(NSNotification*)note {
    NSLog(@"EpgStore: %@ - appWillEnterForeground", _statsEpgName);
    [self removeOldProgramsFromStore];
    
    if ( [self isLastEpgFromThePast] || [self.tvhServer.channelStore channelCount] > self.epgStore.count ) {
        self.epgStore = nil;
        self.totalEventCount = 0;
        [self downloadEpgList];
    }
}

- (void)removeOldProgramsFromStore {
    [epgUpdateInProgress lock];
    BOOL __block didRemove = false;
    NSMutableArray *myStore = [[NSMutableArray alloc] init];
    if ( self.epgStore ) {
        for ( TVHEpg *obj in self.epgStore ) {
            if ( [obj progress] >= 1.0 ) {
                didRemove = true;
            } else {
                [myStore addObject:obj];
            }
        }
    }
    if ( didRemove ) {
        self.epgStore = [myStore copy];
        for ( TVHEpg *obj in self.epgStore ) {
            [self addEpgItemToStoreByChannel:obj];
        }
        [self signalDidLoadEpg];
    }
    [epgUpdateInProgress unlock];
}

- (BOOL)isLastEpgFromThePast {
    TVHEpg *last = [self.epgStore lastObject];
    return ( last && [last.start compare:[NSDate date]] == NSOrderedDescending );
}


- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    self.statsEpgName = @"Shared";
    epgUpdateInProgress = [NSLock new];
    
    return self;
}

- (id)initWithStatsEpgName:(NSString*)statsEpgName withTvhServer:(TVHServer*)tvhServer {
    self = [self initWithTvhServer:tvhServer];
    if (!self) return nil;
    
    self.statsEpgName = statsEpgName;
    epgUpdateInProgress = [NSLock new];
    
    return self;
}

- (void)setStatsEpgName:(NSString *)statsEpgName {
    _statsEpgName = [NSString stringWithFormat:@"EpgStore-%@", statsEpgName];
}

- (NSArray*)epgStore {
    if ( !_epgStore ) {
        _epgStore = [[NSArray alloc] init];
        _epgByChannel = [[NSMutableDictionary alloc] init];
    }
    return _epgStore;
}

- (NSMutableDictionary*)epgByChannel {
    if ( !_epgByChannel ) {
        _epgByChannel = [[NSMutableDictionary alloc] init];
    }
    return _epgByChannel;
}

- (NSDictionary*)epgByChannelCopy {
    return [self.epgByChannel copy];
}

/**
 * channels for the epgByChannel dictionary 
 **/
- (NSArray*)channelsOfEpgByChannel {
    NSMutableArray *channels = [[NSMutableArray alloc] init];
    
    // for each epgByChannel first entry, we shall collect the channelId and then get the corresponding object
    [self.epgByChannel enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull channelIdKey, NSArray*  _Nonnull epgArray, BOOL * _Nonnull stop) {
        TVHEpg *epg = [epgArray objectAtIndex:0];
        if (epg != nil) {
            TVHChannel *channel = epg.channelObject;
            if (channel != nil) {
                [channels addObject:channel];
            }
        }
    }];
    
    if ( [self.tvhServer.settings sortChannel] == TVHS_SORT_CHANNEL_BY_NAME ) {
        return [channels sortedArrayUsingSelector:@selector(compareByName:)];
    } else {
        return [channels sortedArrayUsingSelector:@selector(compareByNumber:)];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.epgStore = nil;
    self.filterToChannelName = nil;
    self.filterToProgramTitle = nil;
    self.filterToTagName = nil;
}

- (BOOL)addEpgItemToStore:(TVHEpg*)epgItem {
    // don't add duplicate items - need to search in the array!
    if ( [self.epgStore indexOfObject:epgItem] == NSNotFound ) {
        self.epgStore = [self.epgStore arrayByAddingObject:epgItem];
        [self addEpgItemToStoreByChannel:epgItem];
        return YES;
    }
#ifdef TESTING
    else {
        NSLog(@"[EpgStore-%@: duplicate EPG: %@", self.statsEpgName, [epgItem title] );
    }
#endif
    return NO;
}

- (void)addEpgItemToStoreByChannel:(TVHEpg*)epgItem {
    NSString *channelIdKey = epgItem.channelIdKey;
    NSArray *channelEpg = [self.epgByChannel objectForKey:channelIdKey];
    if (channelEpg == nil) {
        channelEpg = [[NSArray alloc] init];
    }
    channelEpg = [channelEpg arrayByAddingObject:epgItem];
    [self.epgByChannel setObject:channelEpg forKey:channelIdKey];
}

#pragma mark ApiClient Implementation

- (NSString*)jsonApiFieldEntries {
    return @"entries";
}

- (bool)fetchedData:(NSData *)responseData {
    __block NSUInteger duplicate = 0;
    NSError __autoreleasing *error;
    NSDate *nowTime = [NSDate dateWithTimeIntervalSinceNow:-600];
    NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseData error:&error];
    if( error ) {
        if ([self.delegate respondsToSelector:@selector(didErrorLoadingEpgStore:)]) {
            [self.delegate didErrorLoadingEpgStore:error];
        }
        return false;
    }
    
    [epgUpdateInProgress lock];
    
    self.totalEventCount = [[json objectForKey:@"totalCount"] intValue];
    NSArray *entries = [json objectForKey:self.jsonApiFieldEntries];

    for (id obj in entries) {
        TVHEpg *epg = [[TVHEpg alloc] initWithTvhServer:self.tvhServer];
        [epg updateValuesFromDictionary:obj];
        if ([epg.end timeIntervalSinceDate:nowTime] > 0) {
            if (![self addEpgItemToStore:epg]) {
                duplicate++;
            }
        }
    }
    
    if (self.lastStartDate == nil) {
        self.lastStartDate = [NSDate date];
    }
    self.lastStart += (entries.count - duplicate);
    
    [epgUpdateInProgress unlock];
    
    [self.tvhServer.analytics setIntValue:self.epgStore.count forKey:[NSString stringWithFormat:@"event_epgStoreCount_%@", self.statsEpgName]];
    [self.tvhServer.analytics setIntValue:self.totalEventCount forKey:[NSString stringWithFormat:@"event_totalEventCount_%@", self.statsEpgName]];
    
#ifdef TESTING
    NSLog(@"[%@: Loaded EPG programs (ch:%@ | pr:%@ | tag:%@ | evcount:%d)]: %d", self.statsEpgName, self.filterToChannelName, self.filterToProgramTitle, self.filterToTagName, (int)self.totalEventCount, (int)[self.epgStore count]);
#endif
    return true;
}

- (NSDictionary*)apiParameters {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%d", (int)self.filterStart ],
                                   @"start",
                                   [NSString stringWithFormat:@"%d", (int)self.filterLimit ],
                                   @"limit",nil];
    
    if( self.filterToChannelName != nil ) {
        [params setObject:self.filterToChannelName forKey:@"channel"];
    }
    
    if( self.filterToProgramTitle != nil ) {
        [params setObject:self.filterToProgramTitle forKey:@"title"];
    }
    
    if( self.filterToTagName != nil ) {
        [params setObject:self.filterToTagName forKey:@"tag"];
    }
    
    if( self.filterToContentTypeId != nil ) {
        [params setObject:self.filterToContentTypeId forKey:@"contenttype"];
    }
    
    return [params copy];
}

- (NSString*)apiPath {
    return @"epg";
}

- (NSString*)apiMethod {
    return @"POST";
}

- (void)retrieveEpgDataFromTVHeadend:(NSInteger)start limit:(NSInteger)limit fetchAll:(BOOL)fetchAll {
    
    self.filterStart = start;
    self.filterLimit = limit;
    
    [self signalWillLoadEpg];
#ifdef TESTING
    NSLog(@"[%@ EPG Going to call (total event count:%d)]: %@", self.statsEpgName, (int)self.totalEventCount, self.apiParameters);
#endif
    __block NSDate *profilingDate = [NSDate date];
    __weak typeof (self) weakSelf = self;
    [self.apiClient doApiCall:self
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        if( ! (strongSelf.filterStart == start && strongSelf.filterLimit == limit) ) {
#ifdef TESTING
            NSLog(@"[%@ Wrong EPG received - discarding request.", strongSelf.statsEpgName );
#endif
            return ;
        }
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:profilingDate];
        [strongSelf.tvhServer.analytics sendTimingWithCategory:@"Network Profiling"
                                   withValue:time
                                    withName:weakSelf.statsEpgName
                                   withLabel:nil];
#ifdef TESTING
        NSLog(@"[%@ Profiling Network]: %f", weakSelf.statsEpgName, time);
#endif
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            if ( [strongSelf fetchedData:responseObject] ) {
                if ([strongSelf getMoreEpg:start limit:limit fetchAll:fetchAll]) {
                    [strongSelf signalDidLoadEpgButWillLoadMore];
                } else {
                    [strongSelf signalDidLoadEpg];
                }
            }
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"[EpgStore HTTPClient Error]: %@", error.localizedDescription);
        [weakSelf signalDidErrorLoadingEpgStore:error];
    }];
    
}

- (BOOL)getMoreEpg:(NSInteger)start limit:(NSInteger)limit fetchAll:(BOOL)fetchAll {
    if ( start > self.totalEventCount ) {
        NSLog(@"Reached the end of the epg!");
        return NO;
    }
    // get last epg
    // check date
    // if date > datenow, get more 50 (DEFAULT_REQUEST_EPG_ITEMS)
    if ( fetchAll ) {
        if ( (start+limit) < self.totalEventCount ) {
            [self retrieveEpgDataFromTVHeadend:(start+limit) limit:MAX_REQUEST_EPG_ITEMS fetchAll:true];
            return YES;
        }
    } else {
        TVHEpg *last = [self.epgStore lastObject];
        if ( last ) {
            NSDate *localDate = [NSDate dateWithTimeIntervalSinceNow:SECONDS_TO_FETCH_AHEAD_EPG_ITEMS];
    #ifdef TESTING
            //NSLog(@"localdate: %@ | last start date: %@ ", localDate, last.start);
    #endif
            if ( [localDate compare:last.start] == NSOrderedDescending && (start+limit) < self.totalEventCount ) {
                [self retrieveEpgDataFromTVHeadend:(start+limit) limit:self.numberOfRequestedEpgItems fetchAll:false];
                return YES;
            }
        } else {
            [self retrieveEpgDataFromTVHeadend:(start+limit) limit:self.numberOfRequestedEpgItems fetchAll:false];
            return YES;
        }
    }
    
    return NO;
}

- (NSInteger)numberOfRequestedEpgItems {
    return DEFAULT_REQUEST_EPG_ITEMS;
}

- (void)downloadAllEpgItems {
    [self retrieveEpgDataFromTVHeadend:0 limit:300 fetchAll:true];
}

- (void)downloadEpgList {
    [self retrieveEpgDataFromTVHeadend:0 limit:self.numberOfRequestedEpgItems fetchAll:false];
}

- (void)downloadMoreEpgList {
    // only cache the lastStart for 1 hours. after that we reload everything from the start!
    if (self.lastStartDate != nil && [self.lastStartDate timeIntervalSinceNow] < -3600) {
        self.lastStartDate = nil;
        self.lastStart = 0;
    }
    [self retrieveEpgDataFromTVHeadend:self.lastStart limit:self.numberOfRequestedEpgItems fetchAll:false];
}

- (void)clearEpgData {
    self.epgStore = nil;
}

- (NSArray*)epgStoreItems{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for ( TVHEpg *epg in self.epgStore ) {
        if ( [epg progress] < 100 ) {
            [items addObject:epg];
        }
    }
    return [items copy];
}

- (void)setDelegate:(id <TVHEpgStoreDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

- (void)setFilterToProgramTitle:(NSString *)filterToProgramTitle {
    if( ! [filterToProgramTitle isEqualToString:_filterToProgramTitle] ) {
        _filterToProgramTitle = filterToProgramTitle;
        self.epgStore = nil;
    }
}

- (void)setFilterToChannel:(TVHChannel *)filterToChannel {
    if ( ! [filterToChannel.name isEqualToString:_filterToChannelName] ) {
        _filterToChannelName = filterToChannel.name;
        self.epgStore = nil;
    }
}

- (void)setFilterToTagName:(NSString *)filterToTagName {
    if ( ! [filterToTagName isEqualToString:_filterToTagName] ) {
        _filterToTagName = filterToTagName;
        self.epgStore = nil;
    }
}

- (void)setFilterToContentTypeId:(NSString *)filterToContentTypeId {
    if ( ! [filterToContentTypeId isEqualToString:_filterToContentTypeId] ) {
        _filterToContentTypeId = filterToContentTypeId;
        self.epgStore = nil;
    }
}

- (void)signalWillLoadEpg {
    if ([self.delegate respondsToSelector:@selector(willLoadEpg)]) {
        [self.delegate willLoadEpg];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TVHEpgStoreWillLoadNotification
                                                        object:self];
}

- (void)signalDidLoadEpg {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadEpg)]) {
            [self.delegate didLoadEpg];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHEpgStoreDidLoadNotification
                                                            object:self];
    });
}

- (void)signalDidLoadEpgButWillLoadMore {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadEpgButWillLoadMore)]) {
            [self.delegate didLoadEpgButWillLoadMore];
        }
    });
}

- (void)signalDidErrorLoadingEpgStore:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(didErrorLoadingEpgStore:)]) {
        [self.delegate didErrorLoadingEpgStore:error];
    }
}


@end
