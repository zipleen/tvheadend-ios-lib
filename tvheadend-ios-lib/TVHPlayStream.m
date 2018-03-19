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
@property (nonatomic, weak) TVHApiClient *apiClient;
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
    self.apiClient = tvhServer.apiClient;
    
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
#ifdef ENABLE_EXTERNAL_APPS
    // we need to figure out if this is going to complete true. so let's hack this and ask for a random url just to return false if not
    if ([self URLforProgramWithName:program forURL:@"http://test.com"] == nil) {
        return false;
    }
    [self streamObject:streamObject withInternalPlayer:NO completion:^(NSString *streamUrl) {
        NSURL *myURL = [self URLforProgramWithName:program forURL:streamUrl];
        if ( myURL ) {
            [self.tvhServer.analytics sendEventWithCategory:@"playTo"
                                                 withAction:@"Internal"
                                                  withLabel:program
                                                  withValue:[NSNumber numberWithInt:1]];
            [[UIApplication sharedApplication] openURL:myURL];
        }
    }];
    return true;
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

- (BOOL)streamObject:(id<TVHPlayStreamDelegate>)streamObject withInternalPlayer:(BOOL)internal completion:(void(^)(NSString* streamUrl))completion {
    NSString *streamUrl;
    if (internal) {
        // internal iOS player wants a playlist
        streamUrl = [self addProfileToUrl:streamObject.playlistStreamURL];
        
        // if we can't get a playlist url, well fallback to something that we know could break, but we could be lucky!
        if (streamUrl == nil) {
            streamUrl = [self addProfileToUrl:streamObject.streamURL];
        }
        
        completion(streamUrl);
        return true;
    }
    
    // if the server has correct authentication method, just use what we've used before
    if (self.tvhServer.hasCorrectAuthenticationMethods) {
        completion([self addProfileToUrl:streamObject.streamURL]);
        return true;
    }
    
    // because Digest auth does not allow sending user:pass urls, we require using the ?ticket=XX bypass. for that we'll need to download the playlist and extract the url
    streamUrl = [self addProfileToUrl:streamObject.playlistStreamURL];
    
    // dvr do not have a valid playlist url because /playlist/dvrfile does not exist, and /playlist/dvrid/ID does not work because it requires an id we do not have! (we only have uuid)
    // if for some reason we do not have admin rights, attempt to playback using basic.. maybe we have basic enabled so we do not break backwards compatibility
    if (streamUrl == nil) {
        completion([self addProfileToUrl:streamObject.streamURL]);
        return true;
    }
    
    if (streamUrl != nil) {
        [self.apiClient getPath:streamUrl parameters:nil success:^(NSURLSessionDataTask *task, NSData *responseObject) {
            // well I'm not going to bundle an entire library for reading m3u when I only care about the one line that starts with http....
            // if the channel names have weird broken characters, this initWithData will fail... oh ffs...
            NSString* m3uReply = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSArray* allLinedStrings = [m3uReply componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            for(NSString* line in allLinedStrings) {
                if ([line hasPrefix:@"http"]) {
                    completion(line);
                    return;
                }
            }
            
            NSLog(@"The downloaded m3u did not contain a link starting with http?!");
        } failure:nil];
        return true;
    }
    
    
    return false;
}

- (NSString*)addProfileToUrl:(NSString*)streamUrl {
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
