//
//  TVHStatusConnectionStoreA15.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 18/04/2018.
//  Copyright (c) 2018 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHStatusConnectionStoreA15.h"
#import "TVHServer.h"

@interface TVHStatusConnectionStoreA15()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *connections;
@end

@implementation TVHStatusConnectionStoreA15

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSubscriptionNotification:)
                                                 name:TVHStatusConnectionStoreReloadNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchStatusConnections)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.connections = nil;
}

- (void)receiveSubscriptionNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:TVHStatusConnectionStoreReloadNotification]) {
        NSDictionary *message = (NSDictionary*)[notification object];
        
        if ( [[message objectForKey:@"reload"] intValue] == 1 ) {
            [self fetchStatusConnections];
        }
        
        if ( [[message objectForKey:@"updateEntry"] intValue] == 1 ) {
            for (TVHStatusConnection* obj in self.connections) {
                if ( obj.id == [[message objectForKey:@"id"] intValue] ) {
                    [obj updateValuesFromDictionary:message];
                }
            }
        }
        
        [self signalDidLoadStatusConnection];
    }
}

- (BOOL)fetchedData:(NSDictionary *)json {
    if (![TVHApiClient checkFetchedData:json]) {
        return false;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *connections = [[NSMutableArray alloc] initWithCapacity:entries.count];
    
    for (id obj in entries) {
        TVHStatusConnection *statusConnection = [[TVHStatusConnection alloc] initWithTvhServer:self.tvhServer];
        [statusConnection updateValuesFromDictionary:obj];
        
        [connections addObject:statusConnection];
    }
    
    self.connections = [connections copy];
    
#ifdef TESTING
    NSLog(@"[Loaded Status Connections]: %d", (int)[self.connections count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.connections count] forKey:@"statusConnections"];
    return true;
}

- (NSArray*)connectionsCopy {
    return self.connections.copy;
}

- (TVHStatusConnection*)findConnectionStartedAt:(NSDate*)startedAt withPeer:(NSString*)peer {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peer == %@ AND started == %@", peer, [NSNumber numberWithDouble:[startedAt timeIntervalSince1970]]];
    NSArray *filteredArray = [self.connections filteredArrayUsingPredicate:predicate];
    if ([filteredArray count] > 0) {
        return [filteredArray objectAtIndex:0];
    }
    return nil;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return @"api/status/connections";
}

- (NSDictionary*)apiParameters {
    return nil;
}

- (void)fetchStatusConnections {
    if (!self.tvhServer.userHasAdminAccess) {
        return [self signalDidLoadStatusConnection];
    }
    
    __weak typeof (self) weakSelf = self;
    
    [self signalWillLoadStatusConnection];
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ( [strongSelf fetchedData:responseObject] ) {
                [strongSelf signalDidLoadStatusConnection];
            }
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf signalDidErrorStatusConnectionStore:error];
        NSLog(@"[Status Connection HTTPClient Error]: %@", error.localizedDescription);
    }];
}

- (void)setDelegate:(id <TVHStatusConnectionDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

#pragma mark Signal delegates

- (void)signalDidLoadStatusConnection {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadStatusConnection)]) {
            [self.delegate didLoadStatusConnection];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusConnectionStoreDidLoadNotification
                                                            object:self];
    });
}

- (void)signalWillLoadStatusConnection {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(willLoadStatusConnection)]) {
            [self.delegate willLoadStatusConnection];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusConnectionStoreWillLoadNotification
                                                            object:self];
    });
}

- (void)signalDidErrorStatusConnectionStore:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didErrorStatusConnectionStore:)]) {
            [self.delegate didErrorStatusConnectionStore:error];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusConnectionStoreDidErrorNotification
                                                            object:error];
    });
}

@end
