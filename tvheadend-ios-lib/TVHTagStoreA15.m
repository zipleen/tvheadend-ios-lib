//
//  TVHTagStore40.m
//  TvhClient
//
//  Created by Luis Fernandes on 04/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHTagStoreA15.h"

@implementation TVHTagStoreA15

- (NSString*)apiPath {
    return @"api/channeltag/grid";
}

- (NSDictionary*)apiParameters {
    return @{@"op":@"list", @"limit":@"99999999"};
}

@end
