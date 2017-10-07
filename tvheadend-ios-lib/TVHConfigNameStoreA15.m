//
//  TVHConfigNameStoreA15.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 25/09/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import "TVHConfigNameStoreA15.h"
#import "TVHServer.h"

@interface TVHConfigNameStoreA15()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *configNames;
@end

@implementation TVHConfigNameStoreA15
- (NSString*)apiMethod {
    return @"POST";
}

- (NSString*)apiPath {
    return @"api/idnode/load";
}

- (NSDictionary*)apiParameters {
    return @{@"enum":@"1", @"class":@"dvrconfig"};
}

- (BOOL)fetchedData:(NSDictionary *)json {
    if (![TVHApiClient checkFetchedData:json]) {
        return false;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *configNames = [[NSMutableArray alloc] init];
    
    for (NSDictionary *obj in entries) {
        TVHConfigName *config = [TVHConfigName new];
        config.identifier = [obj objectForKey:@"key"];
        config.name = [obj objectForKey:@"val"];
        [configNames addObject:config];
    };
    
    _configNames = configNames;
#ifdef TESTING
    NSLog(@"[ConfigNames Channels]: %@", _configNames);
#endif
    [self.tvhServer.analytics setIntValue:[_configNames count] forKey:@"configNames"];
    return true;
}

@end
