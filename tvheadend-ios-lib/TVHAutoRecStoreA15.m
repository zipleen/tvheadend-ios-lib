//
//  TVHAutoRecStore40.m
//  TvhClient
//
//  Created by zipleen on 11/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHAutoRecStoreA15.h"

@implementation TVHAutoRecStoreA15

- (NSString*)apiMethod {
    return @"POST";
}

- (NSString*)apiPath {
    return @"api/dvr/autorec/grid";
}

- (NSDictionary*)apiParameters {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"title", @"sort", @"ASC", @"dir", nil];
}

@end
