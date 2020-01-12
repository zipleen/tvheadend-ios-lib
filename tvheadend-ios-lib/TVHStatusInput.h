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


// /*
//  * Input stream structure - used for getting statistics about active streams
//  */
// struct tvh_input_stream_stats
// {
//   int signal; ///< signal strength, value depending on signal_scale value:
//               ///<  - SCALE_RELATIVE : 0...65535 (which means 0%...100%)
//               ///<  - SCALE DECIBEL  : 0.0001 dBm units. This value is generally negative.
//   int snr;    ///< signal to noise ratio, value depending on snr_scale value:
//               ///<  - SCALE_RELATIVE : 0...65535 (which means 0%...100%)
//               ///<  - SCALE DECIBEL  : 0.0001 dB units.
//   int ber;    ///< bit error rate (driver/vendor specific value!)
//   int unc;    ///< number of uncorrected blocks
//   int bps;    ///< bandwidth (bps)
//   int cc;     ///< number of continuity errors
//   int te;     ///< number of transport errors
//
//   signal_status_scale_t signal_scale;
//   signal_status_scale_t snr_scale;
//
//   /* Note: if tc_bit > 0, BER = ec_bit / tc_bit (0...1) else BER = ber (driver specific value) */
//   int ec_bit;    ///< ERROR_BIT_COUNT (same as unc?)
//   int tc_bit;    ///< TOTAL_BIT_COUNT
//
//   /* Note: PER = ec_block / tc_block (0...1) */
//   int ec_block;  ///< ERROR_BLOCK_COUNT
//   int tc_block;  ///< TOTAL_BLOCK_COUNT
// };


@class TVHServer;

@interface TVHStatusInput : NSObject
@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) NSString *input;
@property (nonatomic) float ber;  // ber = error_bit_count / total_bit_count
@property (nonatomic) float per;  // per = error_block_count / total_block_count
@property (nonatomic) NSInteger bps; // this is BITS, divide this number by 1024 to get kb/s
@property (strong, nonatomic) NSString *stream;
@property (nonatomic) NSInteger subs;
@property (nonatomic) NSInteger unc; // uncorrected blocks
@property (nonatomic) NSInteger weight;
@property (nonatomic) float snr;
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
- (NSString*)signalValue;
- (NSString*)snrValue;
@end
