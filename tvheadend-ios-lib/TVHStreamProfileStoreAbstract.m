//
//  TVHStreamProfileStoreAbstract.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 25/09/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import "TVHStreamProfileStoreAbstract.h"
#import "TVHStreamProfile.h"
#import "TVHServer.h"

@interface TVHStreamProfileStoreAbstract ()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *profiles;
@property (nonatomic, strong) dispatch_queue_t profileQueue;
@end

@implementation TVHStreamProfileStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    _profiles = @[];
    _profileQueue = dispatch_queue_create("com.zipleen.TvhClient.profileQueue",
                                           DISPATCH_QUEUE_CONCURRENT);
    return self;
}

- (BOOL)fetchedData:(NSDictionary *)json {
    if (![TVHApiClient checkFetchedData:json]) {
        return false;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *profiles = [[NSMutableArray alloc] initWithCapacity:entries.count];
    
    for (NSDictionary *obj in entries) {
        TVHStreamProfile *profile = [TVHStreamProfile new];
        profile.key = [obj objectForKey:@"key"];
        profile.name = [obj objectForKey:@"val"];
        [profiles addObject:profile];
    };
    
    dispatch_barrier_sync(self.profileQueue, ^{
        self.profiles = profiles;
    });
#ifdef TESTING
    NSLog(@"[Stream Profiles]: %@", self.profiles);
#endif
    [self.tvhServer.analytics setIntValue:[_profiles count] forKey:@"profiles"];
    return true;
}

- (NSArray*)profilesAsString {
    __block NSMutableArray *asString = [[NSMutableArray alloc] initWithCapacity:self.profiles.count];
    dispatch_sync(self.profileQueue, ^{
        for (TVHStreamProfile* streamProfile in self.profiles) {
            [asString addObject:streamProfile.name];
        }
    });
    return [asString copy];
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return @"api/profile/list";
}

- (NSDictionary*)apiParameters {
    return @{};
}

- (void)fetchStreamProfiles {
    
    __weak typeof (self) weakSelf = self;
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        if ( [strongSelf fetchedData:responseObject] ) {
            // signal
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"[Stream Profiles HTTPClient Error]: %@", error.localizedDescription);
    }];
}
@end
