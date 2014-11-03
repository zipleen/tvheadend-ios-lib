//
//  TVHEpgStoreA12.m
//  tvheadend-ios-lib
//
//  Created by zipleen on 03/11/14.
//  Copyright (c) 2014 zipleen. All rights reserved.
//

#import "TVHEpgStoreA12.h"

@implementation TVHEpgStoreA12

- (NSString*)jsonApiFieldEntries {
    return @"events";
}

- (NSString*)apiPath {
    return @"api/epg/grid";
}

@end
