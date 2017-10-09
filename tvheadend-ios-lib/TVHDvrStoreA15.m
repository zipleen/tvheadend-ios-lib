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

#import "TVHDvrStoreA15.h"

@interface TVHDvrStoreAbstract()
@property (nonatomic, strong) NSArray *dvrItems;
- (void)fetchDvrItemsFromServer:(NSString*)url withType:(NSInteger)type start:(NSInteger)start limit:(NSInteger)limit ;
@property NSInteger filterStart;
@property NSInteger filterLimit;
@end

@implementation TVHDvrStoreA15

- (NSDictionary*)apiParameters {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithFormat:@"%d", (int)self.filterStart ],
            @"start",
            [NSString stringWithFormat:@"%d", (int)self.filterLimit ],
            @"limit",
            @"start_real",
            @"sort",
            nil];
}

- (NSString*)jsonApiFieldEntries {
    return @"entries";
}

- (NSString*)jsonApiFieldTotalCount {
    return @"total";
}

- (void)fetchDvr {
    [self clearDvrItems];
    
    [self fetchDvrItemsFromServer:@"api/dvr/entry/grid_upcoming" withType:RECORDING_UPCOMING start:0 limit:20];
    [self fetchDvrItemsFromServer:@"api/dvr/entry/grid_finished" withType:RECORDING_FINISHED start:0 limit:20];
    [self fetchDvrItemsFromServer:@"api/dvr/entry/grid_failed" withType:RECORDING_FAILED start:0 limit:20];
}

@end
