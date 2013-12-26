//
//  TVHNetwork.h
//  tvheadend-ios-lib
//
//  Created by zipleen on 23/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TVHServer;
@class TVHMux;

@interface TVHNetwork : NSObject
@property (strong, nonatomic) NSString *uuid;

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)updateValuesFromDictionary:(NSDictionary*)values;

- (NSArray*)networkMuxes;
- (NSArray*)networkServicesForMux:(TVHMux*)adapterMux;
@end
