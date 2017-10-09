//
//  TVHPlayStream.m
//  TvhClient
//
//  Created by Luis Fernandes on 26/10/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHPlayStream.h"
#import "TVHServer.h"

#ifdef ENABLE_XBMC
#import "TVHPlayXbmc.h"
#define TVH_ICON_XBMC @"icon-xbmc.png"
#endif

#ifdef ENABLE_CHROMECAST
#import "TVHPlayChromeCast.h"
#define TVH_ICON_CHROMECAST @"icon-cast-identified.png"
#endif

#define TVH_PROGRAMS @{@"VLC":@"vlc", @"Oplayer":@"oplayer", @"Buzz Player":@"buzzplayer", @"GoodPlayer":@"goodplayer", @"Ace Player":@"aceplayer", @"nPlayer":@"nplayer-http" }
#define TVH_PROGRAMS_REMOVE_HTTP @[ @"nplayer-http" ]

#define TVH_ICON_PROGRAM @""

@interface TVHPlayStream()
@property (nonatomic, weak) TVHServer *tvhServer;
@end

@implementation TVHPlayStream

- (id)init {
    [NSException raise:@"Invalid Init" format:@"TVHPlayStream needs TVHServer to work"];
    return nil;
}

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    NSParameterAssert(tvhServer);
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    
    return self;
}

#pragma MARK get programs

- (NSDictionary*)arrayOfAvailablePrograms {
    NSMutableDictionary *available = [[NSMutableDictionary alloc] init];
#ifdef ENABLE_EXTERNAL_APPS
    for (NSString* key in TVH_PROGRAMS) {
        NSString *urlTarget = [TVH_PROGRAMS objectForKey:key];
        NSURL *url = [self urlForSchema:urlTarget withURL:nil];
        if( [[UIApplication sharedApplication] canOpenURL:url] ) {
            [available setObject:TVH_ICON_PROGRAM forKey:key];
        }
    }
#endif
    
#ifdef ENABLE_XBMC
    // xbmc
    for (NSString* xbmcServer in [[TVHPlayXbmc sharedInstance] availableServers]) {
        [available setObject:TVH_ICON_XBMC forKey:xbmcServer];
    }
#endif
#ifdef ENABLE_CHROMECAST
        // chromecast - can only cast with transcoding, no "mkv" or "mpeg2" support...
        for (NSString* ccServer in [[TVHPlayChromeCast sharedInstance] availableServers]) {
            [available setObject:TVH_ICON_CHROMECAST forKey:ccServer];
        }
#endif
    
    return [available copy];
}

#pragma mark play stream

- (BOOL)playStreamIn:(NSString*)program forObject:(id<TVHPlayStreamDelegate>)streamObject {
    
    if ( [self playInternalStreamIn:program forObject:streamObject] ) {
        return true;
    }
#ifdef ENABLE_XBMC
    if ( [self playToXbmc:program forObject:streamObject] ) {
        return true;
    }
#endif
#ifdef ENABLE_CHROMECAST
    return [self playToChromeCast:program forObject:streamObject];
#else
    return false;
#endif
}

- (BOOL)playInternalStreamIn:(NSString*)program forObject:(id<TVHPlayStreamDelegate>)streamObject {
#ifndef DEVICE_IS_TVOS
    NSString *streamUrl = [streamObject streamUrlWithInternalPlayer:NO];
    NSURL *myURL = [self URLforProgramWithName:program forURL:streamUrl];
    if ( myURL ) {
        [self.tvhServer.analytics sendEventWithCategory:@"playTo"
                                             withAction:@"Internal"
                                              withLabel:program
                                              withValue:[NSNumber numberWithInt:1]];
        [[UIApplication sharedApplication] openURL:myURL];
        return true;
    }
#endif
    return false;
}

#ifdef ENABLE_XBMC
- (BOOL)playToXbmc:(NSString*)xbmcName forObject:(id<TVHPlayStreamDelegate>)streamObject {
    TVHPlayXbmc *playXbmcService = [TVHPlayXbmc sharedInstance];
    return [playXbmcService playStream:xbmcName forObject:streamObject withAnalytics:self.tvhServer.analytics];
}
#endif
#ifdef ENABLE_CHROMECAST
- (BOOL)playToChromeCast:(NSString*)xbmcName forObject:(id<TVHPlayStreamDelegate>)streamObject {
    TVHPlayChromeCast *playChromeCastService = [TVHPlayChromeCast sharedInstance];
    return [playChromeCastService playStream:xbmcName forObject:streamObject withAnalytics:self.tvhServer.analytics];
}
#endif

- (NSString*)streamUrlForObject:(id<TVHPlayStreamDelegate>)streamObject withInternalPlayer:(BOOL)internal {
    NSString *streamUrl;
    if ( internal ) {
        // internal iOS player wants a playlist
        streamUrl = streamObject.playlistStreamURL;
    } else {
        streamUrl = streamObject.streamURL;
    }
    
    // add profile!
    if (self.tvhServer.settings.streamProfile != nil && ![self.tvhServer.settings.streamProfile isEqualToString:@""]) {
        return [streamUrl stringByAppendingFormat:@"?profile=%@", [self.tvhServer.settings.streamProfile stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    }
    
    return streamUrl;
}

- (NSURL*)URLforProgramWithName:(NSString*)title forURL:(NSString*)streamUrl {
    NSString *prefix = [TVH_PROGRAMS objectForKey:title];
    if ( prefix ) {
        NSURL *myURL = [self urlForSchema:prefix withURL:streamUrl];
        return myURL;
    }
    
    return nil;
}

- (NSURL*)urlForSchema:(NSString*)schema withURL:(NSString*)url {
    if ( [TVH_PROGRAMS_REMOVE_HTTP indexOfObject:schema] != NSNotFound ) {
        url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", schema, url]];
}

@end
