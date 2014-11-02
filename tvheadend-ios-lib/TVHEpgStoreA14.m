//
//  TVHEpgStoreA14.m
//  tvheadend-ios-lib
//
//  Created by zipleen on 02/11/14.
//  Copyright (c) 2014 zipleen. All rights reserved.
//

#import "TVHEpgStoreA14.h"

@implementation TVHEpgStoreA14

- (NSString*)jsonApiFieldEntries {
    return @"events";
}

- (NSString*)apiPath {
    return @"api/epg/data/grid";
}

@end
