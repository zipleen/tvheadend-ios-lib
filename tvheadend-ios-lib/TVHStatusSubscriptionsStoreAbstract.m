//
//  TVHStatusSubscriptionsStore.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/18/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHStatusSubscriptionsStoreAbstract.h"
#import "TVHServer.h"

@interface TVHStatusSubscriptionsStoreAbstract()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *subscriptions;
@end

@implementation TVHStatusSubscriptionsStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSubscriptionNotification:)
                                                 name:TVHStatusSubscriptionStoreReloadNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchStatusSubscriptions)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.subscriptions = nil;
}

- (void)receiveSubscriptionNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:TVHStatusSubscriptionStoreReloadNotification]) {
        NSDictionary *message = (NSDictionary*)[notification object];
        
        if ( [[message objectForKey:@"reload"] intValue] == 1 ) {
            [self fetchStatusSubscriptions];
        }
        
        for (TVHStatusSubscription* obj in self.subscriptions) {
            if ( obj.id == [[message objectForKey:@"id"] intValue] ) {
                [obj updateValuesFromDictionary:message];
            }
        }
        
        [self signalDidLoadStatusSubscriptions];
    }
}

- (BOOL)fetchedData:(NSDictionary *)json {
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *subscriptions = [[NSMutableArray alloc] initWithCapacity:entries.count];
    
    for (id obj in entries) {
        TVHStatusSubscription *subscription = [[TVHStatusSubscription alloc] init];
        [subscription updateValuesFromDictionary:obj];
        
        [subscriptions addObject:subscription];
    }
    
    entries = nil;
    
    self.subscriptions = [subscriptions copy];
    
    subscriptions = nil;
    
#ifdef TESTING
    NSLog(@"[Loaded Subscription]: %d", (int)[self.subscriptions count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.subscriptions count] forKey:@"subscriptions"];
    return true;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return @"subscriptions";
}

- (NSDictionary*)apiParameters {
    return nil;
}

- (void)fetchStatusSubscriptions {
    if (!self.tvhServer.userHasAdminAccess) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    
    [self signalWillLoadStatusSubscriptions];
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            typeof (self) strongSelf = weakSelf;
            if ( [strongSelf fetchedData:responseObject] ) {
                [strongSelf signalDidLoadStatusSubscriptions];
            }
        //});
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf signalDidErrorStatusSubscriptionsStore:error];
        NSLog(@"[Subscription HTTPClient Error]: %@", error.localizedDescription);
    }];
}

- (TVHStatusSubscription *) objectAtIndex:(int) row {
    if ( row < [self.subscriptions count] ) {
        return [self.subscriptions objectAtIndex:row];
    }
    return nil;
}

- (int)count {
    return (int)[self.subscriptions count];
}

- (void)setDelegate:(id <TVHStatusSubscriptionsDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

#pragma mark Signal delegates

- (void)signalDidLoadStatusSubscriptions {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadStatusSubscriptions)]) {
            [self.delegate didLoadStatusSubscriptions];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusSubscriptionStoreDidLoadNotification
                                                            object:self];
    });
    
}

- (void)signalWillLoadStatusSubscriptions {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(willLoadStatusSubscriptions)]) {
            [self.delegate willLoadStatusSubscriptions];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusSubscriptionStoreWillLoadNotification
                                                            object:self];
    });
}

- (void)signalDidErrorStatusSubscriptionsStore:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didErrorStatusSubscriptionsStore:)]) {
            [self.delegate didErrorStatusSubscriptionsStore:error];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusSubscriptionStoreDidErrorNotification
                                                            object:error];
    });
}

@end
