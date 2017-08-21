//
//  TVHConfigNameStore.m
//  TvhClient
//
//  Created by Luis Fernandes on 7/17/13.
//  Copyright (c) 2013 Luis Fernandes. 
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHConfigNameStore.h"
#import "TVHServer.h"

@interface TVHConfigNameStore ()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *configNames;
@end

@implementation TVHConfigNameStore

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    return self;
}

- (BOOL)fetchedData:(NSDictionary *)json {
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *configNames = [[NSMutableArray alloc] init];
    
    [entries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        TVHConfigName *config = [[TVHConfigName alloc] init];
        [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [config setValue:obj forKey:key];
        }];
        [configNames addObject:config];
        
    }];
    
    _configNames = configNames;
#ifdef TESTING
    NSLog(@"[ConfigNames Channels]: %@", _configNames);
#endif
    [self.tvhServer.analytics setIntValue:[_configNames count] forKey:@"configNames"];
    return true;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"POST";
}

- (NSString*)apiPath {
    return @"confignames";
}

- (NSDictionary*)apiParameters {
    return @{@"op":@"list"};
}

- (void)fetchConfigNames {
    if (!self.tvhServer.userHasAdminAccess) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        if ( [strongSelf fetchedData:responseObject] ) {
            // signal
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"[ConfigNames HTTPClient Error]: %@", error.localizedDescription);
    }];
}

@end
