//
//  TVHNetwork.m
//  tvheadend-ios-lib
//
//  Created by zipleen on 23/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHNetwork.h"
#import "TVHServer.h"

@interface TVHNetwork()
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) TVHJsonClient *jsonClient;
@end

@implementation TVHNetwork
- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.jsonClient = [self.tvhServer jsonClient];
    
    return self;
}

- (void)updateValuesFromDictionary:(NSDictionary*) values {
    [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

- (NSArray*)networkMuxes
{
    return nil;
}

- (NSArray*)networkServicesForMux:(TVHMux*)mux
{
    id <TVHServiceStore> serviceStore = [self.tvhServer serviceStore];
    return [serviceStore servicesForMux:mux];
}

@end
