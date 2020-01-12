//
//  TVHStatusSubscription.h
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/18/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

@class TVHServer;
#import "TVHChannel.h"

@interface TVHStatusSubscription : NSObject
@property (strong, nonatomic) NSString *channel;
@property NSInteger errors;
@property (strong, nonatomic) NSString *hostname;
@property NSInteger id;
@property (strong, nonatomic) NSString *service;
@property (strong, nonatomic) NSDate *start;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSString *title;
@property NSInteger bw; // old "in" variable for < 4.0

// 4.0
@property NSInteger in;
@property NSInteger out;
@property (strong, nonatomic) NSString *descramble;
@property (strong, nonatomic) NSString *profile;
@property (strong, nonatomic) NSString *username;
@property NSInteger total_in;
@property NSInteger total_out;

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)updateValuesFromDictionary:(NSDictionary*) values;
- (NSInteger)bandwidth; // .in from 4.0, .bw from <4 . This is Bytes per second, so divide/125 to get kb/s
- (TVHChannel*)mappedChannel;
- (void)killConnection;
@end
