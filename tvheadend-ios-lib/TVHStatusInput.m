//
//  TVHStatusInputs.m
//  TvhClient
//
//  Created by zipleen on 09/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
#import "TVHStatusInput.h"

@interface TVHStatusInput()
@property (nonatomic, weak) TVHServer *tvhServer;
@end

@implementation TVHStatusInput
- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    
    return self;
}

- (void)updateValuesFromDictionary:(NSDictionary*) values {
    [values enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
    
}

- (NSInteger)signal
{
    if (self.signal_scale == 1)
        return (_signal / 65535) * 100;
    if (self.signal_scale == 2 && _signal > 0) {
        float snr = _signal * 0.0001;
        return (snr / 65535) * 100 ;
    }
    return 0;
}

- (NSInteger)ber
{
    if (self.tc_bit == 0)
        return _ber; // fallback (driver/vendor dependent ber)
    
    // ber = error_bit_count / total_bit_count
    return self.ec_bit / self.tc_bit;
}

- (NSInteger)per
{
    if (_tc_block == 0) {
        return 0;
    }
    
    // per = error_block_count / total_block_count
    return self.ec_block / self.tc_block;
}

@end
