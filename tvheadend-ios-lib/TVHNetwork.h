//
//  TVHNetwork.h
//  tvheadend-ios-lib
//
//  Created by zipleen on 23/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHMuxStore.h"

@class TVHServer;
@class TVHMux;

@interface TVHNetwork : NSObject <TVHMuxNetwork>
@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) NSString *networkname;
@property (nonatomic) NSInteger autodiscovery;
@property (strong, nonatomic) NSString *charset;
@property (nonatomic) NSInteger nid;
@property (nonatomic) NSInteger num_mux;
@property (nonatomic) NSInteger num_svc;
@property (nonatomic) NSInteger max_streams;
@property (nonatomic) NSInteger scanq_length;
@property (nonatomic) NSInteger skipinitscan;

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)updateValuesFromDictionary:(NSDictionary*)values;

- (NSArray*)networkMuxes;
- (NSArray*)networkServicesForMux:(TVHMux*)adapterMux;
@end
