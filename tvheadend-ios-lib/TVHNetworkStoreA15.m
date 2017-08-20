//
//  TVHNetworkStore40.m
//  tvheadend-ios-lib
//
//  Created by zipleen on 23/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHNetworkStoreA15.h"
#import "TVHServer.h"

@interface TVHNetworkStoreA15()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *networks;
@end

@implementation TVHNetworkStoreA15

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNetworkNotification:)
                                                 name:TVHNetworkStoreReloadNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchNetworks)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.networks = nil;
}

- (void)receiveNetworkNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:TVHNetworkStoreReloadNotification]) {
        NSDictionary *message = (NSDictionary*)[notification object];
        
        if ( [[message objectForKey:@"reload"] intValue] == 1 ) {
            [self fetchNetworks];
        }
        
        for (TVHNetwork* obj in self.networks) {
            if ([[message objectForKey:@"uuid"] isEqualToString:obj.uuid]) {
                [obj updateValuesFromDictionary:message];
            }
        }
        
        [self signalDidLoadNetwork];
    }
}

- (BOOL)fetchedData:(NSData *)responseData {
    NSError __autoreleasing *error;
    NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseData error:&error];
    if (error) {
        [self signalDidErrorNetworkStore:error];
        return false;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *networks = [[NSMutableArray alloc] initWithCapacity:entries.count];
    
    for (id obj in entries) {
        TVHNetwork *network = [[TVHNetwork alloc] initWithTvhServer:self.tvhServer];
        [network updateValuesFromDictionary:obj];
        
        [networks addObject:network];
    }
    
    self.networks = [networks copy];
    
#ifdef TESTING
    NSLog(@"[Loaded Networks]: %d", (int)[self.networks count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.networks count] forKey:@"networks"];
    return true;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return @"api/mpegts/network/grid";
}

- (NSDictionary*)apiParameters {
    return @{@"limit":@"99999999"};
}


- (void)fetchNetworks {
    if (!self.tvhServer.userHasAdminAccess) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    
    [self signalWillLoadNetwork];
    [self.apiClient doApiCall:self success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if ( [strongSelf fetchedData:responseObject] ) {
                [strongSelf signalDidLoadNetwork];
            }
        });

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [weakSelf signalDidErrorNetworkStore:error];
        NSLog(@"[Network HTTPClient Error]: %@", error.localizedDescription);
    }];
}

- (TVHNetwork *)objectAtIndex:(NSUInteger) row {
    if ( row < [self.networks count] ) {
        return [self.networks objectAtIndex:row];
    }
    return nil;
}

- (int)count {
    return (int)[self.networks count];
}

- (void)setDelegate:(id <TVHNetworkDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

#pragma mark Signal delegates

- (void)signalDidLoadNetwork {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadNetwork)]) {
            [self.delegate didLoadNetwork];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHNetworkStoreDidLoadNotification
                                                            object:self];
    });
    
}

- (void)signalWillLoadNetwork {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(willLoadNetwork)]) {
            [self.delegate willLoadNetwork];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHNetworkStoreWillLoadNotification
                                                            object:self];
    });
}

- (void)signalDidErrorNetworkStore:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didErrorNetworkStore:)]) {
            [self.delegate didErrorNetworkStore:error];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHNetworkStoreDidErrorNotification
                                                            object:error];
    });
}

@end
