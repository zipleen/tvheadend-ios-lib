//
//  TVHPlayStreamDelegate.h
//  TvhClient
//
//  Created by Luis Fernandes on 06/03/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
@class TVHEpg;

@protocol TVHPlayStreamDelegate <NSObject>
- (NSString*)streamURL;
- (NSString*)playlistStreamURL;
- (NSString*)htspStreamURL;
- (NSString*)streamUrlWithTranscoding:(BOOL)transcoding withInternal:(BOOL)internal;
- (BOOL)isLive;

- (NSString*)imageUrl;
- (NSString*)name;
- (NSString*)description;
- (TVHEpg*)currentPlayingProgram;
@end
