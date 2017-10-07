//
//  TVHApiClient.h
//  TvhClient
//
//  Created by Luis Fernandes on 03/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHJsonClient.h"

@protocol TVHApiClientDelegate <NSObject>
- (NSDictionary*)apiParameters;
- (NSString*)apiMethod;
- (NSString*)apiPath;
@end

/**
  The ApiClient is trying to hide the implementation details of AFNetworking. 
  With this, the Stores can ask for whatever they need and all network code is abstracted from them.
 */
@interface TVHApiClient : NSObject
- (id)initWithClient:(TVHJsonClient*)jsonClient;
- (void)doApiCall:(id <TVHApiClientDelegate>)object
          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
          failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

- (NSURLSessionDataTask*)getPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
- (NSURLSessionDataTask*)postPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

+ (BOOL)checkFetchedData:(NSDictionary*) json;
@end
