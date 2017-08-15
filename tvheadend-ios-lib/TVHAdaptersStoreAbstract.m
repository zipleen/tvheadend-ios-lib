//
//  TVHAdaptersStore.m
//  TvhClient
//
//  Created by Luis Fernandes on 06/03/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHAdaptersStoreAbstract.h"
#import "TVHServer.h"

@interface TVHAdaptersStoreAbstract()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *adapters;
@end

@implementation TVHAdaptersStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSubscriptionNotification:)
                                                 name:TVHAdapterStoreReloadNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchAdapters)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.adapters = nil;
}

- (void)receiveSubscriptionNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:TVHAdapterStoreReloadNotification]) {
        NSDictionary *message = (NSDictionary*)[notification object];
        
        for (TVHAdapter* obj in self.adapters) {
            if ( [obj.identifier isEqualToString:[message objectForKey:@"identifier"]] ) {
                [obj updateValuesFromDictionary:message];
            }
        }
        
        [self signalDidLoadAdapters];
    }
}

- (BOOL)fetchedData:(NSData *)responseData {
    NSError __autoreleasing *error;
    NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseData error:&error];
    if (error) {
        [self signalDidErrorAdaptersStore:error];
        return false;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *adapters = [[NSMutableArray alloc] initWithCapacity:entries.count];
    
    for (id obj in entries) {
        TVHAdapter *adapter = [[TVHAdapter alloc] initWithTvhServer:self.tvhServer];
        [adapter updateValuesFromDictionary:obj];
        [self setupMoreValuesForAdapter:adapter];
        
        [adapters addObject:adapter];
    }
    
    self.adapters = [adapters copy];
    
#ifdef TESTING
    NSLog(@"[Loaded Adapters]: %d", (int)[self.adapters count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.adapters count] forKey:@"adapters"];
    return true;
}

- (void)setupMoreValuesForAdapter:(TVHAdapter*)adapter {
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return @"tv/adapter";
}

- (NSDictionary*)apiParameters {
    return nil;
}

- (void)fetchAdapters {
    __weak typeof (self) weakSelf = self;
    
    [self.apiClient doApiCall:self success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if ( [strongSelf fetchedData:responseObject] ) {
                [strongSelf signalDidLoadAdapters];
            }
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [weakSelf signalDidErrorAdaptersStore:error];
        NSLog(@"[Adapter Store HTTPClient Error]: %@", error.localizedDescription);
    }];
    
}

- (TVHAdapter *)objectAtIndex:(NSUInteger) row {
    if ( row < [self.adapters count] ) {
        return [self.adapters objectAtIndex:row];
    }
    return nil;
}

- (int)count {
    return (int)[self.adapters count];
}

- (void)setDelegate:(id <TVHAdaptersDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

- (void)signalWillLoadAdapters {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(willLoadAdapters)]) {
            [self.delegate willLoadAdapters];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHAdapterStoreWillLoadNotification
                                                            object:self];
    });
}

- (void)signalDidLoadAdapters {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadAdapters)]) {
            [self.delegate didLoadAdapters];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHAdapterStoreDidLoadNotification
                                                            object:self];
    });
    
}

- (void)signalDidErrorAdaptersStore:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didErrorAdaptersStore:)]) {
            [self.delegate didErrorAdaptersStore:error];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHAdapterStoreDidErrorNotification
                                                            object:error];
    });
}

@end
