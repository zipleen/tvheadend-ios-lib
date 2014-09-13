//
//  TVHDvrStore40.m
//  TvhClient
//
//  Created by Luis Fernandes on 01/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHDvrStore40.h"

@interface TVHDvrStore40()
- (void)fetchDvrItemsFromServer:(NSString*)url withType:(NSInteger)type start:(NSInteger)start limit:(NSInteger)limit ;
@end

@implementation TVHDvrStore40

- (NSString*)jsonApiFieldEntries {
    return @"entries";
}

- (NSString*)jsonApiFieldTotalCount {
    return @"total";
}

- (void)fetchDvr {
    self.dvrItems = nil;
    self.cachedDvrItems = nil;
    
    [self fetchDvrItemsFromServer:@"api/dvr/entry/grid_upcoming" withType:RECORDING_UPCOMING start:0 limit:20];
    [self fetchDvrItemsFromServer:@"api/dvr/entry/grid_finished" withType:RECORDING_FINISHED start:0 limit:20];
    [self fetchDvrItemsFromServer:@"api/dvr/entry/grid_failed" withType:RECORDING_FAILED start:0 limit:20];
}

@end
