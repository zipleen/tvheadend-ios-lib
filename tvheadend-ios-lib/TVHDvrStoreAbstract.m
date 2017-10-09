//
//  TVHDvrStore.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 28/02/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHDvrStoreAbstract.h"
#import "TVHServer.h"

@interface TVHDvrStoreAbstract()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSMutableArray *dvrItems;
@property (nonatomic, strong) NSMutableArray *totalEventCount;
@property (nonatomic, strong) dispatch_queue_t dvrStoreQueue;
@property NSInteger filterStart;
@property NSInteger filterLimit;
@property (nonatomic, strong) NSString *filterPath;
@end

@implementation TVHDvrStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveDvrdbNotification:)
                                                 name:TVHDvrStoreReloadNotification
                                               object:nil];
    
    _dvrStoreQueue = dispatch_queue_create("com.zipleen.TvhClient.dvrStoreQueue",
                                           DISPATCH_QUEUE_CONCURRENT);
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.dvrItems = nil;
}

- (void)receiveDvrdbNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:TVHDvrStoreReloadNotification]) {
        NSDictionary *message = (NSDictionary*)[notification object];
        if ( [[message objectForKey:@"reload"] intValue] == 1 ) {
            [self fetchDvr];
        }
    }
}

- (NSMutableArray*)totalEventCount {
    if ( !_totalEventCount ) {
        _totalEventCount = [@[@0,@0,@0,@0] mutableCopy];
    }
    return _totalEventCount;
}

- (NSArray*)dvrItems {
    if ( !_dvrItems ) {
        _dvrItems = [[NSMutableArray alloc] init];
    }
    return _dvrItems;
}

- (TVHDvrItem*)createDvrItemFromDictionary:(NSDictionary*)obj ofType:(NSInteger)type {
    TVHDvrItem *dvritem = [[TVHDvrItem alloc] initWithTvhServer:self.tvhServer];
    [dvritem updateValuesFromDictionary:obj];
    [dvritem setDvrType:type];
    return dvritem;
}

- (NSString*)jsonApiFieldEntries {
    return @"entries";
}

- (NSString*)jsonApiFieldTotalCount {
    return @"totalCount";
}

- (bool)fetchedData:(NSDictionary *)json withType:(NSInteger)type {
    if (![TVHApiClient checkFetchedData:json]) {
        return false;
    }
    
    NSArray *entries = [json objectForKey:self.jsonApiFieldEntries];
    NSNumber *totalCount = [[NSNumber alloc] initWithInt:[[json objectForKey:self.jsonApiFieldTotalCount] intValue]];
    [self.totalEventCount replaceObjectAtIndex:type withObject:totalCount];
    dispatch_barrier_sync(self.dvrStoreQueue, ^{
        
        for (id obj in entries) {
            TVHDvrItem *dvritem = [self createDvrItemFromDictionary:obj ofType:type];
            
            if ([self.dvrItems indexOfObject:dvritem] == NSNotFound) {
                [self.dvrItems addObject:dvritem];
            }
        }
        
    });
    
#ifdef TESTING
    NSLog(@"[Loaded DVR Items, Count]: %d", (int)[self.dvrItems count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.dvrItems count] forKey:[NSString stringWithFormat:@"dvr_%d", (int)type]];
    return true;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return self.filterPath;
}

- (NSDictionary*)apiParameters {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%d", (int)self.filterStart ],
                                   @"start",
                                   [NSString stringWithFormat:@"%d", (int)self.filterLimit ],
                                   @"limit",nil];
}

- (void)fetchDvrItemsFromServer:(NSString*)url withType:(NSInteger)type start:(NSInteger)start limit:(NSInteger)limit {
    [self signalWillLoadDvr:type];
    __block NSDate *profilingDate = [NSDate date];
    
    self.filterPath = url;
    self.filterStart = start;
    self.filterLimit = limit;
    
    __weak typeof (self) weakSelf = self;
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:profilingDate];
        [strongSelf.tvhServer.analytics sendTimingWithCategory:@"Network Profiling"
                                   withValue:time
                                    withName:[NSString stringWithFormat:@"DvrStore-%d", (int)type]
                                   withLabel:nil];
#ifdef TESTING
        NSLog(@"[DvrStore Profiling Network]: %f", time);
#endif
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ( [strongSelf fetchedData:responseObject withType:type] ) {
                [strongSelf signalDidLoadDvr:type];
                [strongSelf getMoreDvrItems:url withType:type start:start limit:limit];
            }
        });
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf signalDidErrorDvrStore:error];
        NSLog(@"[DVR Items HTTPClient Error]: %@", error.localizedDescription);
    }];
    
}

- (void)getMoreDvrItems:(NSString*)url withType:(NSInteger)type start:(NSInteger)start limit:(NSInteger)limit {
    if ( (start+limit) < [[self.totalEventCount objectAtIndex:type] intValue] ) {
        [self fetchDvrItemsFromServer:url withType:type start:(start+limit) limit:limit];
    }
}

- (void)clearDvrItems {
    dispatch_barrier_sync(self.dvrStoreQueue, ^{
        self.dvrItems = nil;
    });
}

- (void)fetchDvr {
    [self clearDvrItems];
    
    [self fetchDvrItemsFromServer:@"dvrlist_upcoming" withType:RECORDING_UPCOMING start:0 limit:20];
    [self fetchDvrItemsFromServer:@"dvrlist_finished" withType:RECORDING_FINISHED start:0 limit:20];
    [self fetchDvrItemsFromServer:@"dvrlist_failed" withType:RECORDING_FAILED start:0 limit:20];
}

- (NSArray*)dvrItemsForType:(NSInteger)type {
    NSMutableArray *itemsForType = [[NSMutableArray alloc] init];
    
    dispatch_sync(self.dvrStoreQueue, ^{
        for (TVHDvrItem *item in self.dvrItems) {
            if ( item.dvrType == type ) {
                [itemsForType addObject:item];
            }
        }
    });
    
    return [itemsForType copy];
}

- (NSArray*)dvrItemsForType:(NSInteger)type sorting:(NSComparisonResult)sort {
    NSArray *itemsForType = [self dvrItemsForType:type];
    if (sort == NSOrderedAscending) {
        return [itemsForType sortedArrayUsingSelector:@selector(compareByDateAscending:)];
    } else {
        return [itemsForType sortedArrayUsingSelector:@selector(compareByDateDescending:)];
    }
}

#pragma mark Signal delegate

- (void)signalWillLoadDvr:(NSInteger)type {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(willLoadDvr:)]) {
            [self.delegate willLoadDvr:type];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDvrStoreWillLoadNotification
                                                            object:self];
    });
}

- (void)signalDidLoadDvr:(NSInteger)type {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadDvr:)]) {
            [self.delegate didLoadDvr:type];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDvrStoreDidLoadNotification
                                                            object:self];
    });
}

- (void)signalDidErrorDvrStore:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didErrorDvrStore:)]) {
            [self.delegate didErrorDvrStore:error];
        }
    });
}

@end
