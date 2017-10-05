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
@end

@implementation TVHStreamProfileStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    return self;
}

- (BOOL)fetchedData:(NSDictionary *)json {
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *profiles = [[NSMutableArray alloc] init];
    
    for (NSDictionary *obj in entries) {
        TVHStreamProfile *profile = [TVHStreamProfile new];
        profile.key = [obj objectForKey:@"key"];
        profile.name = [obj objectForKey:@"val"];
        [profiles addObject:profile];
    };
    
    _profiles = profiles;
#ifdef TESTING
    NSLog(@"[Stream Profiles]: %@", _profiles);
#endif
    [self.tvhServer.analytics setIntValue:[_profiles count] forKey:@"profiles"];
    return true;
}

- (NSArray*)profilesAsString {
    NSMutableArray *asString = [[NSMutableArray alloc] initWithCapacity:self.profiles.count];
    for (TVHStreamProfile* streamProfile in self.profiles) {
        [asString addObject:streamProfile.name];
    }
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
