//
//  TVHJsonClient.h
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/22/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <AFNetworking/AFNetworking.h>

@class TVHServerSettings;

#ifndef __TVOS_AVAILABLE
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
@interface TVHNetworkActivityIndicatorManager : AFNetworkActivityIndicatorManager
@end
#endif

@interface TVHJsonClient : AFHTTPSessionManager
@property (nonatomic, readonly) BOOL readyToUse;
- (id)initWithSettings:(TVHServerSettings *)settings;
- (NSURLSessionDataTask*)getPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
- (NSURLSessionDataTask*)postPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

+ (NSDictionary*)convertFromJsonToObject:(NSData*)responseData error:(__autoreleasing NSError**)error;
+ (NSArray*)convertFromJsonToArray:(NSData*)responseData error:(__autoreleasing NSError**)error;
@end
