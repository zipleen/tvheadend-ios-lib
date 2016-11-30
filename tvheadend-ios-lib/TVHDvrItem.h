//
//  TVHDvrItem.h
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 28/02/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import "TVHPlayStreamDelegate.h"

@class TVHChannel;
@class TVHServer;

@interface TVHDvrItem : NSObject <TVHPlayStreamDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, strong) NSString *channel;
@property (nonatomic, strong) NSString *chicon;
@property (nonatomic, strong) NSString *config_name;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *description;
@property (nonatomic) NSInteger id;
@property (nonatomic, strong) NSDate *start;
@property (nonatomic, strong) NSDate *end;
@property (nonatomic) NSInteger duration;
@property (nonatomic, strong) NSString *creator;
@property (nonatomic, strong) NSString *pri;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *schedstate;
@property (nonatomic) unsigned long long filesize;
@property (nonatomic, strong) NSString *url;
@property (nonatomic) NSInteger dvrType;
@property (nonatomic, strong) NSString *episode;

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *disp_title;
@property (nonatomic, strong) NSString *disp_description;
@property (nonatomic, strong) NSString *disp_subtitle;
@property (nonatomic, strong) NSString *sched_status;
@property (nonatomic) NSInteger errorcode;
@property (nonatomic) NSInteger errors;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSDate *start_real;
@property (nonatomic, strong) NSDate *stop_real;

@property (nonatomic, strong) NSString *autorec; // autorec uuid

- (NSString*)fullTitle;

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)updateValuesFromDictionary:(NSDictionary*) values;
- (void)deleteRecording;
- (TVHChannel*)channelObject;
- (BOOL)isRecording;
- (BOOL)isScheduledForRecording;

// playStream delegate

- (NSString*)streamURL;
- (NSString*)playlistStreamURL;
- (NSString*)name;
- (NSString*)imageUrl;
@end
