//
//  TVHTagStore.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/9/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHTagStoreAbstract.h"
#import "TVHServer.h"

@interface TVHTagStoreAbstract()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *tags;
@end

@implementation TVHTagStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchTagList)
                                                 name:TVHTagStoreReloadNotification
                                               object:nil];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.tags = nil;
    self.tvhServer = nil;
    self.apiClient = nil;
}

- (bool)fetchedData:(NSData *)responseData {
    NSError __autoreleasing *error;
    NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseData error:&error];
    if( error ) {
        [self signalDidErrorLoadingTagStore:error];
        return false;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *tags = [[NSMutableArray alloc] init];
    
    [entries enumerateObjectsUsingBlock:^(id entry, NSUInteger idx, BOOL *stop) {
        NSInteger enabled = [[entry objectForKey:@"enabled"] intValue];
        if( enabled ) {
            TVHTag *tag = [[TVHTag alloc] initWithTvhServer:self.tvhServer];
            [tag updateValuesFromDictionary:entry];
            [tags addObject:tag];
        }
    }];
     
    NSMutableArray *orderedTags = [[tags sortedArrayUsingSelector:@selector(compareByName:)] mutableCopy];
    
    // All channels
    TVHTag *tag = [[TVHTag alloc] initWithAllChannels:self.tvhServer];
    [orderedTags insertObject:tag atIndex:0];
    
    self.tags = [orderedTags copy];
#ifdef TESTING
    NSLog(@"[Loaded Tags]: %d", (int)[self.tags count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.tags count] forKey:@"tags"];
    return true;
}

- (TVHTag*)tagWithIdKey:(NSString*)idKey {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"idKey == %@", idKey];
    NSArray *filteredArray = [self.tags filteredArrayUsingPredicate:predicate];
    if ([filteredArray count] > 0) {
        return [filteredArray objectAtIndex:0];
    }
    return nil;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"POST";
}

- (NSString*)apiPath {
    return @"tablemgr";
}

- (NSDictionary*)apiParameters {
    return @{@"op":@"get", @"table":@"channeltags"};
}

- (void)fetchTagList {
    [self signalWillLoadTags];
    __block NSDate *profilingDate = [NSDate date];
    
    __weak typeof (self) weakSelf = self;
    [self.apiClient doApiCall:self success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:profilingDate];
        [strongSelf.tvhServer.analytics sendTimingWithCategory:@"Network Profiling"
                                   withValue:time
                                    withName:@"TagStore"
                                   withLabel:nil];
#ifdef TESTING
        NSLog(@"[TagStore Profiling Network]: %f", time);
#endif
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if ( [strongSelf fetchedData:responseObject] ) {
                [strongSelf signalDidLoadTags];
            }
        });
        
        //NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        //NSLog(@"Request Successful, response '%@'", responseStr);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [weakSelf signalDidErrorLoadingTagStore:error];
        NSLog(@"[TagStore HTTPClient Error]: %@", error.description);
    }];
}

- (void)setDelegate:(id <TVHTagStoreDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

#pragma mark singals

- (void)signalWillLoadTags {
    if ([self.delegate respondsToSelector:@selector(willLoadTags)]) {
        [self.delegate willLoadTags];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TVHTagStoreWillLoadNotification
                                                        object:self];
}

- (void)signalDidLoadTags {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadTags)]) {
            [self.delegate didLoadTags];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHTagStoreDidLoadNotification
                                                            object:self];
    });
    }

- (void)signalDidErrorLoadingTagStore:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(didErrorLoadingTagStore:)]) {
        [self.delegate didErrorLoadingTagStore:error];
    }
}

@end
