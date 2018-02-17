//
//  TVHPlayStream.h
//  TvhClient
//
//  Created by Luis Fernandes on 26/10/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//


#import "TVHPlayStreamDelegate.h"

#define TVHS_VLC_DEBLOCKING @[NSLocalizedString(@"No deblocking (fastest)", @""), NSLocalizedString(@"Low deblocking", @""), NSLocalizedString(@"Medium deblocking", @"")]
#define TVHS_VLC_DEBLOCKING_VALUES @[kVLCSettingSkipLoopFilterNone, kVLCSettingSkipLoopFilterNonKey, kVLCSettingSkipLoopFilterNonRef]
#define TVHS_DEINTERLACE_OPTIONS @[@"", @"auto", @"blend", @"bob", @"linear", @"x", @"yadif", @"ivtc", @"discard", @"mean", @"yadif2x", @"phosphor"]
#define TVHS_DEINTERLACE_OPTIONS_DESC @[NSLocalizedString(@"Off", @""), NSLocalizedString(@"Automatic", @""), NSLocalizedString(@"Blend (ok for HD - default)", @""), NSLocalizedString(@"Bob (ok for HD", @""), NSLocalizedString(@"Linear (Best Performance for HD)", @""), NSLocalizedString(@"X (Slow in HD)", @""), NSLocalizedString(@"Yadif (Slow in HD)", @""), NSLocalizedString(@"IVTC (Slow in HD)", @""), NSLocalizedString(@"Discard (ok for HD)", @""), NSLocalizedString(@"Mean (Good Quality, bad for Sports)", @""), NSLocalizedString(@"Yadif (2x) (Slow in HD)", @""), NSLocalizedString(@"Phosphor(v1.2.0+)", @"")]

// HW OFF , ON
#define TVHS_VLC_HWDECODING @[@"dvbsub,avcodec,all", @""]

#define TVHS_ON_OFF @[NSLocalizedString(@"Off", @""), NSLocalizedString(@"On", @"")]

@class TVHServer;

@interface TVHPlayStream : NSObject
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (NSString*)streamUrlForObject:(id<TVHPlayStreamDelegate>)streamObject withInternalPlayer:(BOOL)internal;

- (NSDictionary*)arrayOfAvailablePrograms;
- (BOOL)playStreamIn:(NSString*)program forObject:(id<TVHPlayStreamDelegate>)streamObject;
@end
