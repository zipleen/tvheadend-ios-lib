//
//  TVHStatusConnection.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 18/04/2018.
//  Copyright (c) 2018 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHServer.h"
#import "TVHStatusConnection.h"

@interface TVHStatusConnection()
@property (nonatomic, weak) TVHServer *tvhServer;
@end

@implementation TVHStatusConnection
- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    
    return self;
}

- (void)updateValuesFromDictionary:(NSDictionary*) values {
    [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

// POST api/connections/cancel?id=1722
- (void)killConnection {
    [self.tvhServer.apiClient postPath:@"api/connections/cancel"
                            parameters:@{@"id":[NSNumber numberWithInteger:self.id]} success:^(NSURLSessionDataTask *task, id responseObject) {
                                NSLog(@"%@", [NSString stringWithFormat:@"Killed connection %ld", self.id]);
                            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                NSLog(@"%@", [NSString stringWithFormat:@"Error killing connection %ld", self.id]);
                            }];
}
@end
