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

#import <Foundation/Foundation.h>
#import "TVHPlayStreamDelegate.h"

#define TVHS_TRANSCODE_RESOLUTIONS @[@"288", @"384", @"480", @"576", @"720"]
#define TVHS_TRANSCODE_VIDEO_OPTIONS @[@"H264", @"VP8", @"MPEG2VIDEO", @"PASS", @"NONE"]
#define TVHS_TRANSCODE_SOUND_OPTIONS @[@"AAC", @"MP3", @"MPEG2AUDIO", @"AC3", @"MP4A", @"VORBIS", @"PASS", @"NONE"]
#define TVHS_TRANSCODE_MUX_OPTIONS @[@"mpegts", @"mp4", @"matroska", @"webm", @"NONE"]

@class TVHServer;

@interface TVHPlayStream : NSObject
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (NSString*)streamUrlForObject:(id<TVHPlayStreamDelegate>)streamObject withTranscoding:(BOOL)transcoding withInternal:(BOOL)internal;

- (NSDictionary*)arrayOfAvailablePrograms:(BOOL)withTranscoding;
- (BOOL)isTranscodingCapable;
- (BOOL)playStreamIn:(NSString*)program forObject:(id<TVHPlayStreamDelegate>)streamObject withTranscoding:(BOOL)transcoding;
@end
