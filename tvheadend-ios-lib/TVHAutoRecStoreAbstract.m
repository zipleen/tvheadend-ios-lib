//
//  TVHAutoRecStore.m
//  TvhClient
//
//  Created by Luis Fernandes on 3/14/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHAutoRecStoreAbstract.h"
#import "TVHServer.h"

@interface TVHAutoRecStoreAbstract()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *dvrAutoRecItems;
@end

@implementation TVHAutoRecStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveAutoRecNotification:)
                                                 name:TVHAutoStoreReloadNotification
                                               object:nil];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.dvrAutoRecItems = nil;
}

- (void)receiveAutoRecNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:TVHAutoStoreReloadNotification]) {
        NSDictionary *message = (NSDictionary*)[notification object];
        if ( [[message objectForKey:@"reload"] intValue] == 1 ) {
            [self fetchDvrAutoRec];
        }
    }
}

- (void)fetchedData:(NSDictionary *)json {
    if (![TVHApiClient checkFetchedData:json]) {
        return;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *dvrAutoRecItems = [[NSMutableArray alloc] initWithCapacity:entries.count];
    
    for(id obj in entries) {
        TVHAutoRecItem *dvritem = [[TVHAutoRecItem alloc] initWithTvhServer:self.tvhServer];
        [dvritem updateValuesFromDictionary:obj];
        
        [dvrAutoRecItems addObject:dvritem];
    }
    
    self.dvrAutoRecItems = [dvrAutoRecItems copy];
    
#ifdef TESTING
    NSLog(@"[Loaded Auto Rec Items, Count]: %d", (int)[self.dvrAutoRecItems count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.dvrAutoRecItems count] forKey:@"autorec"];
}

- (NSArray*)autoRecItemsCopy {
    return [self.dvrAutoRecItems copy];
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return @"tablemgr";
}

- (NSDictionary*)apiParameters {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"get", @"op", @"autorec", @"table", nil];
}

- (void)fetchDvrAutoRec {
    self.dvrAutoRecItems = nil;
    __block NSDate *profilingDate = [NSDate date];
    
    __weak typeof (self) weakSelf = self;
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:profilingDate];
        [strongSelf.tvhServer.analytics sendTimingWithCategory:@"Network Profiling"
                                   withValue:time
                                    withName:@"AutoRec"
                                   withLabel:nil];
#ifdef TESTING
        NSLog(@"[AutoRec Profiling Network]: %f", time);
#endif
        [strongSelf fetchedData:responseObject];
        [strongSelf signalDidLoadDvrAutoRec];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf signalDidErrorDvrAutoStore:error];
        NSLog(@"[DVR AutoRec Items HTTPClient Error]: %@", error.localizedDescription);
    }];
    
}

- (TVHAutoRecItem *)objectAtIndex:(NSUInteger)row {
    if ( row < [self.dvrAutoRecItems count] ) {
        return [self.dvrAutoRecItems objectAtIndex:row];
    }
    return nil;
}

- (int)count {
    if ( self.dvrAutoRecItems ) {
        return (int)[self.dvrAutoRecItems count];
    }
    return 0;
}

- (void)signalWillLoadDvrAutoRec {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(willLoadDvrAutoRec)]) {
            [self.delegate willLoadDvrAutoRec];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHAutoRecStoreWillLoadNotification
                                                            object:self];
    });
}

- (void)signalDidLoadDvrAutoRec {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadDvrAutoRec)]) {
            [self.delegate didLoadDvrAutoRec];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHAutoRecStoreDidLoadNotification
                                                            object:self];
    });
}

- (void)signalDidErrorDvrAutoStore:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didErrorDvrAutoStore:)]) {
            [self.delegate didErrorDvrAutoStore:error];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHAutoRecStoreDidErrorNotification
                                                            object:error];
    });
}

@end
