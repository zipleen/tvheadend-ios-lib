//
//  TVHMuxStore.m
//  TvhClient
//
//  Created by Luis Fernandes on 08/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHMuxStoreAbstract.h"
#import "TVHMux.h"
#import "TVHServer.h"

@interface TVHMuxStoreAbstract()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *muxes;
@end

@implementation TVHMuxStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    return self;
}

- (NSArray*)muxes {
    if ( !_muxes ) {
        _muxes = [[NSArray alloc] init];
    }
    return _muxes;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return nil;
}

- (NSString*)apiPath {
    return nil;
}

- (NSDictionary*)apiParameters {
    return nil;
}

- (void)fetchMuxes {
    if (!self.tvhServer.userHasAdminAccess) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if ( [strongSelf fetchedData:responseObject] ) {
                [strongSelf signalDidLoadAdapterMuxes];
            }
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"[TV Adapter Mux HTTPClient Error]: %@", error.localizedDescription);
    }];
    
}

- (BOOL)fetchedData:(NSDictionary *)json {
   
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *muxes = [self.muxes mutableCopy];
    
    for (id obj in entries) {
        TVHMux *mux = [[TVHMux alloc] initWithTvhServer:self.tvhServer];
        [mux updateValuesFromDictionary:obj];
        
        [self updateMuxToArray:mux array:muxes];
    }
    
    self.muxes = [muxes copy];
    
#ifdef TESTING
    NSLog(@"[Loaded Adapter Muxes]: %d", (int)[self.muxes count]);
#endif
    return true;
}

- (void)updateMuxToArray:(TVHMux*)muxItem array:(NSMutableArray*)muxes {
    NSUInteger indexOfMux = [self.muxes indexOfObject:muxItem];
    if ( indexOfMux == NSNotFound ) {
        [muxes addObject:muxItem];
    } else {
        // update
        TVHMux *foundMux = [muxes objectAtIndex:indexOfMux];
        [foundMux updateValuesFromTVHMux:muxItem];
    }
}

- (NSArray*)muxesFor:(id <TVHMuxNetwork>)network {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"adapterId == %@", [network identifierForNetwork]];
    NSArray *filteredArray = [self.muxes filteredArrayUsingPredicate:predicate];
    
    return [filteredArray sortedArrayUsingSelector:@selector(compareByFreq:)];
}

- (NSArray*)muxesForNetwork:(id <TVHMuxNetwork>)network {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"network == %@", [network identifierForNetwork]];
    NSArray *filteredArray = [self.muxes filteredArrayUsingPredicate:predicate];
    
    return [filteredArray sortedArrayUsingSelector:@selector(compareByFreq:)];
}

- (void)signalDidLoadAdapterMuxes {
    
}

@end
