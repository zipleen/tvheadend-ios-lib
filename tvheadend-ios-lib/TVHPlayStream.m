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
#define TVHS_TVHEADEND_STREAM_URL_INTERNAL @"?transcode=1&resolution=%@&vcodec=H264%@&scodec=PASS&mux=mpegts"
#define TVHS_TVHEADEND_STREAM_URL @"?transcode=1&resolution=%@%@%@%@&scodec=PASS"

#define TVH_ICON_PROGRAM @""

@interface TVHPlayStream()
@property (nonatomic, weak) TVHServer *tvhServer;
@end

@implementation TVHPlayStream

- (id)init
{
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

- (NSDictionary*)arrayOfAvailablePrograms:(BOOL)withTranscoding {
    NSMutableDictionary *available = [[NSMutableDictionary alloc] init];
    for (NSString* key in TVH_PROGRAMS) {
        NSString *urlTarget = [TVH_PROGRAMS objectForKey:key];
        NSURL *url = [self urlForSchema:urlTarget withURL:nil];
        if( [[UIApplication sharedApplication] canOpenURL:url] ) {
            [available setObject:TVH_ICON_PROGRAM forKey:key];
        }
    }
    
    // custom
    NSString *customPrefix = [self.tvhServer.settings customPrefix];
    if( [customPrefix length] > 0 ) {
        NSURL *url = [self urlForSchema:customPrefix withURL:nil];
        if( [[UIApplication sharedApplication] canOpenURL:url] ) {
            [available setObject:TVH_ICON_PROGRAM forKey:NSLocalizedString(@"Custom Player", nil)];
        }
    }
    
#ifdef ENABLE_XBMC
    // xbmc
    for (NSString* xbmcServer in [[TVHPlayXbmc sharedInstance] availableServers]) {
        [available setObject:TVH_ICON_XBMC forKey:xbmcServer];
    }
#endif
#ifdef ENABLE_CHROMECAST
    if ( withTranscoding ) {
        // chromecast - can only cast with transcoding, no "mkv" or "mpeg2" support...
        for (NSString* ccServer in [[TVHPlayChromeCast sharedInstance] availableServers]) {
            [available setObject:TVH_ICON_CHROMECAST forKey:ccServer];
        }
    }
#endif
    
    return [available copy];
}

- (BOOL)isTranscodingCapable {
    return [self.tvhServer isTranscodingCapable];
}

#pragma mark play stream

- (BOOL)playStreamIn:(NSString*)program forObject:(id<TVHPlayStreamDelegate>)streamObject withTranscoding:(BOOL)transcoding {
    
    if ( [self playInternalStreamIn:program forObject:streamObject withTranscoding:transcoding] ) {
        return true;
    }
#ifdef ENABLE_XBMC
    if ( [self playToXbmc:program forObject:streamObject withTranscoding:transcoding] ) {
        return true;
    }
#endif
#ifdef ENABLE_CHROMECAST
    return [self playToChromeCast:program forObject:streamObject withTranscoding:transcoding];
#else
    return false;
#endif
}

- (BOOL)playInternalStreamIn:(NSString*)program forObject:(id<TVHPlayStreamDelegate>)streamObject withTranscoding:(BOOL)transcoding {
    NSString *streamUrl = [streamObject streamUrlWithTranscoding:transcoding withInternal:NO];
    NSURL *myURL = [self URLforProgramWithName:program forURL:streamUrl];
    if ( myURL ) {
        [self.tvhServer.analytics sendEventWithCategory:@"playTo"
                                             withAction:@"Internal"
                                              withLabel:program
                                              withValue:[NSNumber numberWithInt:1]];
        [[UIApplication sharedApplication] openURL:myURL];
        return true;
    }
    return false;
}

#ifdef ENABLE_XBMC
- (BOOL)playToXbmc:(NSString*)xbmcName forObject:(id<TVHPlayStreamDelegate>)streamObject withTranscoding:(BOOL)transcoding {
    TVHPlayXbmc *playXbmcService = [TVHPlayXbmc sharedInstance];
    return [playXbmcService playStream:xbmcName forObject:streamObject withTranscoding:transcoding withAnalytics:self.tvhServer.analytics];
}
#endif
#ifdef ENABLE_CHROMECAST
- (BOOL)playToChromeCast:(NSString*)xbmcName forObject:(id<TVHPlayStreamDelegate>)streamObject withTranscoding:(BOOL)transcoding {
    TVHPlayChromeCast *playChromeCastService = [TVHPlayChromeCast sharedInstance];
    return [playChromeCastService playStream:xbmcName forObject:streamObject withTranscoding:transcoding withAnalytics:self.tvhServer.analytics];
}
#endif

- (NSString*)streamUrlForObject:(id<TVHPlayStreamDelegate>)streamObject withTranscoding:(BOOL)transcoding withInternal:(BOOL)internal
{
    NSString *streamUrl;
    if ( internal ) {
        streamUrl = streamObject.playlistStreamURL;
    } else {
        streamUrl = streamObject.streamURL;
    }
    
    if ( transcoding ) {
        if ( internal ) {
            return [self stringTranscodeUrlInternalFormat:streamUrl];
        } else {
            return [self stringTranscodeUrl:streamUrl];
        }
    } else {
        return streamUrl;
    }
}


- (NSString*)stringTranscodeUrl:(NSString*)url {
    NSString *video = @"";
    NSString *sound = @"";
    NSString *mux = @"";
    if (![self.tvhServer.settings.transcodeVideo isEqualToString:@"NONE"]) {
        video = [NSString stringWithFormat:@"&vcodec=%@", self.tvhServer.settings.transcodeVideo];
    }
    if (![self.tvhServer.settings.transcodeSound isEqualToString:@"NONE"]) {
        sound = [NSString stringWithFormat:@"&acodec=%@", self.tvhServer.settings.transcodeSound];
    }
    if (![self.tvhServer.settings.transcodeMux isEqualToString:@"NONE"]) {
        mux = [NSString stringWithFormat:@"&mux=%@", self.tvhServer.settings.transcodeMux];
    }
    return [url stringByAppendingFormat:TVHS_TVHEADEND_STREAM_URL, self.tvhServer.settings.transcodeResolution, video, sound, mux];
}

- (NSString*)stringTranscodeUrlInternalFormat:(NSString*)url {
    NSString *sound = @"";
    if (![self.tvhServer.settings.transcodeSound isEqualToString:@"NONE"]) {
        sound = [NSString stringWithFormat:@"&acodec=%@", self.tvhServer.settings.transcodeSound];
    }
    return [url stringByAppendingFormat:TVHS_TVHEADEND_STREAM_URL_INTERNAL, self.tvhServer.settings.transcodeResolution, sound];
}

- (NSURL*)URLforProgramWithName:(NSString*)title forURL:(NSString*)streamUrl {
    NSString *prefix = [TVH_PROGRAMS objectForKey:title];
    if ( prefix ) {
        NSURL *myURL = [self urlForSchema:prefix withURL:streamUrl];
        return myURL;
    }
    
    if ( [title isEqualToString:NSLocalizedString(@"Custom Player", nil)] ) {
        NSString *customPrefix = [self.tvhServer.settings customPrefix];
        NSString *url = [NSString stringWithFormat:@"%@://%@", customPrefix, streamUrl ];
        NSURL *myURL = [NSURL URLWithString:url];
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
