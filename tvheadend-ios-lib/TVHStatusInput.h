//
//  TVHStatusInputs.h
//  TvhClient
//
//  Created by zipleen on 09/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

@class TVHServer;

@interface TVHStatusInput : NSObject
@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) NSString *input;
@property (nonatomic) float ber;  // ber = error_bit_count / total_bit_count
@property (nonatomic) float per;  // per = error_block_count / total_block_count
@property NSInteger bps;
@property (strong, nonatomic) NSString *stream;
@property NSInteger subs;
@property NSInteger unc; // uncorrected blocks
@property NSInteger weight;
@property float snr;
@property (nonatomic) float signal;

// 4.0
@property NSInteger signal_scale;
@property NSInteger snr_scale;
@property NSInteger te; // transport errors
@property NSInteger cc; // continuity errors
@property NSInteger ec_bit; // error_bit_count 
@property NSInteger tc_bit; // total_bit_count
@property NSInteger ec_block; // error_block_count
@property NSInteger tc_block; // total_block_count // per = error_block_count / total_block_count

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)updateValuesFromDictionary:(NSDictionary*) values;

@end
