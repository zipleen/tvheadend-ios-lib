//
//  TVHDvrActions.h
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/28/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
@class TVHServer;
@class TVHDvrItem;

@interface TVHDvrActions : NSObject
+ (void)addRecording:(NSInteger)eventId withConfigName:(NSString*)configName withTvhServer:(TVHServer*)tvhServer;
+ (void)cancelRecording:(NSInteger)eventId withTvhServer:(TVHServer*)tvhServer;
+ (void)deleteRecording:(NSInteger)eventId withTvhServer:(TVHServer*)tvhServer;
+ (void)addAutoRecording:(NSInteger)eventId withConfigName:(NSString*)configName withTvhServer:(TVHServer*)tvhServer;

+ (void)doIdnodeAction:(NSString*)action withData:(NSDictionary*)params withTvhServer:(TVHServer*)tvhServer;
+ (void)doAction:(NSString*)action withData:(NSDictionary*)params withTvhServer:(TVHServer*)tvhServer;
+ (NSString*)jsonArrayString:(id)params;
@end
