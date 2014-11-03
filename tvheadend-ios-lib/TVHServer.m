//
//  TVHServer.m
//  TvhClient
//
//  Created by Luis Fernandes on 16/05/2013.
//  Copyright (c) 2013 Luis Fernandes. 
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHServer.h"
#import "TVHPlayXbmc.h"
#import "TVHPlayChromeCast.h"

#define TVH_LATEST_SUPPORTED_API @"A15"

@interface TVHServer()
@property (nonatomic, strong) TVHJsonClient *jsonClient;
@property (nonatomic, strong) TVHApiClient *apiClient;
@property (nonatomic, strong) id <TVHTagStore> tagStore;
@property (nonatomic, strong) id <TVHChannelStore> channelStore;
@property (nonatomic, strong) id <TVHDvrStore> dvrStore;
@property (nonatomic, strong) id <TVHAutoRecStore> autorecStore;
@property (nonatomic, strong) id <TVHStatusSubscriptionsStore> statusStore;
@property (nonatomic, strong) id <TVHAdaptersStore> adapterStore;
@property (nonatomic, strong) id <TVHMuxStore> muxStore;
@property (nonatomic, strong) id <TVHServiceStore> serviceStore;
@property (nonatomic, strong) TVHLogStore *logStore;
@property (nonatomic, strong) id <TVHCometPoll> cometStore;
@property (nonatomic, strong) TVHConfigNameStore *configNameStore;
@property (nonatomic, strong) id <TVHStatusInputStore> inputStore;
@property (nonatomic, strong) id <TVHNetworkStore> networkStore;
@property (nonatomic, strong) NSString *version;     // version like 32, 34, 40 - legacy only!
@property (nonatomic, strong) NSString *realVersion; // real version number, unmodified
@property (nonatomic, strong) NSNumber *apiVersion;  // the new API JSON version 
@property (nonatomic, strong) NSArray *capabilities;
@property (nonatomic, strong) NSDictionary *configSettings;
@property (nonatomic, strong) NSTimer *timer;
@property (atomic) BOOL inProcessing;
@end

@implementation TVHServer 

#pragma mark NSNotification

- (void)appWillResignActive:(NSNotification*)note {
    [self stopTimer];
}

- (void)appWillEnterForeground:(NSNotification*)note {
    [self processTimerEvents];
    [self startTimer];
}

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(processTimerEvents) userInfo:nil repeats:YES];
    if ([self.timer respondsToSelector:@selector(setTolerance:)]) {
        [self.timer setTolerance:10];
    }
}

- (void)stopTimer
{
    if ( self.timer ) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)processTimerEvents {
    if ( ! self.inProcessing ) {
        self.inProcessing = YES;
        [self.channelStore updateChannelsProgress];
        self.inProcessing = NO;
    }
}

#pragma mark init

- (TVHServer*)initWithSettings:(TVHServerSettings*)settings {
    self = [super init];
    if (self) {
        if ( ! settings ) {
            return nil;
        }
        self.inProcessing = NO;
        [TVHPlayXbmc sharedInstance];
        [TVHPlayChromeCast sharedInstance];
        self.settings = settings;
        self.version = settings.version;
        self.apiVersion = settings.apiVersion;
        [self.tagStore fetchTagList];
        [self.channelStore fetchChannelList];
        [self.statusStore fetchStatusSubscriptions];
        [self.adapterStore fetchAdapters];
        [self.networkStore fetchNetworks];
        [self.inputStore fetchStatusInputs];
        [self.muxStore fetchMuxes];
        [self.serviceStore fetchServices];
        [self logStore];
        [self fetchServerVersion];
        if ( ! [self.version isEqualToString:@"32"] ) {
            [self fetchCapabilities];
        }
        [self.configNameStore fetchConfigNames];
        [self fetchConfigSettings];
        [self cometStore];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [self startTimer];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelAllOperations];
}

- (void)cancelAllOperations {
    if ( _jsonClient ) {
        [[self.jsonClient operationQueue] cancelAllOperations];
    }
    [self stopTimer];
    if ( _cometStore ) {
        [self.cometStore stopRefreshingCometPoll];
    }
    
    self.jsonClient = nil;
    self.tagStore = nil;
    self.channelStore = nil;
    self.dvrStore = nil;
    self.autorecStore = nil;
    self.statusStore = nil;
    self.adapterStore = nil;
    self.cometStore = nil;
    self.configNameStore = nil;
    self.capabilities = nil;
    self.version = nil;
    self.realVersion = nil;
    self.configSettings = nil;
    self.inputStore = nil;
    self.muxStore = nil;
    self.serviceStore = nil;
    self.logStore = nil;
    self.networkStore = nil;
}

#pragma mark Main Objects

- (id)factory:(NSString*)className
{
    Class myClass = NSClassFromString([className stringByAppendingString:self.version]);
    if ( !myClass ) {
        myClass = NSClassFromString([className stringByAppendingString:TVH_LATEST_SUPPORTED_API]);
    }
    return [[myClass alloc] initWithTvhServer:self];
}

- (id <TVHTagStore>)tagStore {
    if( ! _tagStore ) {
        _tagStore = [self factory:@"TVHTagStore"];
    }
    return _tagStore;
}

- (id <TVHChannelStore>)channelStore {
    if( ! _channelStore ) {
        _channelStore = [self factory:@"TVHChannelStore"];
    }
    return _channelStore;
}

- (id <TVHDvrStore>)dvrStore {
    if( ! _dvrStore ) {
        _dvrStore = [self factory:@"TVHDvrStore"];
    }
    return _dvrStore;
}

- (id <TVHAutoRecStore>)autorecStore {
    if( ! _autorecStore ) {
        _autorecStore = [self factory:@"TVHAutoRecStore"];
    }
    return _autorecStore;
}

- (id <TVHStatusSubscriptionsStore>)statusStore {
    if( ! _statusStore ) {
        _statusStore = [self factory:@"TVHStatusSubscriptionsStore"];
    }
    return _statusStore;
}

- (id <TVHAdaptersStore>)adapterStore {
    if( ! _adapterStore ) {
        _adapterStore = [self factory:@"TVHAdaptersStore"];
    }
    return _adapterStore;
}

- (id <TVHStatusInputStore>)inputStore {
    if( ! _inputStore ) {
        _inputStore = [self factory:@"TVHStatusInputStore"];
    }
    return _inputStore;
}

- (id <TVHMuxStore>)muxStore {
    if( ! _muxStore ) {
        _muxStore = [self factory:@"TVHMuxStore"];
    }
    return _muxStore;
}

- (id <TVHServiceStore>)serviceStore {
    if( ! _serviceStore ) {
        _serviceStore = [self factory:@"TVHServiceStore"];
    }
    return _serviceStore;
}

- (id <TVHNetworkStore>)networkStore {
    if( ! _networkStore ) {
        _networkStore = [self factory:@"TVHNetworkStore"];
    }
    return _networkStore;
}

- (TVHLogStore*)logStore {
    if( ! _logStore ) {
        _logStore = [[TVHLogStore alloc] init];
    }
    return _logStore;
}

- (id <TVHCometPoll>)cometStore {
    if( ! _cometStore ) {
        _cometStore = [self factory:@"TVHCometPoll"];
        if ( self.settings.autoStartPolling ) {
            [_cometStore startRefreshingCometPoll];
        }
    }
    return _cometStore;
}

- (TVHJsonClient*)jsonClient {
    if( ! _jsonClient ) {
        _jsonClient = [[TVHJsonClient alloc] initWithSettings:self.settings];
    }
    return _jsonClient;
}

- (TVHApiClient*)apiClient {
    if( ! _apiClient ) {
        _apiClient = [[TVHApiClient alloc] initWithClient:self.jsonClient];
    }
    return _apiClient;
}

- (TVHConfigNameStore*)configNameStore {
    if( ! _configNameStore ) {
        _configNameStore = [[TVHConfigNameStore alloc] initWithTvhServer:self];
    }
    return _configNameStore;
}

- (id <TVHEpgStore>)createEpgStoreWithName:(NSString*)statsName {
    Class myClass = NSClassFromString([@"TVHEpgStore" stringByAppendingString:self.version]);
    id <TVHEpgStore> epgStore = [[myClass alloc] initWithStatsEpgName:statsName withTvhServer:self];
    return epgStore;
}

- (NSString*)version {
    // apiVersion has the real HTTP JSON API version - no more guessing
    if ( _apiVersion && _apiVersion > 0 ) {
        return [@"A" stringByAppendingFormat:@"%@", _apiVersion];
    }
    
    // the api http version has only been introduced in the middle of 3.9 development.
    // use the old method to support 3.2 , 3.4 and 3.6
    if ( _version ) {
        int ver = [_version intValue];
        if ( ver >= 30 && ver <= 32 ) {
            return @"32";
        }
        if ( ver >= 33 && ver <= 35 ) {
            return @"34";
        }
        if ( ver >= 36 ) {
            return TVH_LATEST_SUPPORTED_API;
        }
    }
    return @"34";
}

- (BOOL)isVersionFour
{
    if (self.apiVersion) {
        return true;
    }
    
    if ([self.version isEqualToString:@"40"]) {
        return true;
    }
    return false;
}

- (TVHPlayStream*)playStream
{
    if ( ! _playStream ) {
        _playStream = [[TVHPlayStream alloc] initWithTvhServer:self];
    }
    return _playStream;
}

#pragma mark fetch version

- (void)fetchServerVersion {
    __weak typeof (self) weakSelf = self;
    [self.jsonClient getPath:@"api/serverinfo" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSError *error;
        NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseObject error:&error];
        if( error ) {
            NSLog(@"[TVHServer fetchCapabilities]: error %@", error.description);
            return ;
        }
        
        // this capabilities seems to retrieve a different array from /capabilities
        //strongSelf.capabilities = [json valueForKey:@"capabilities"];
        strongSelf.apiVersion = [json valueForKey:@"api_version"];
        strongSelf.realVersion = [json valueForKey:@"sw_version"];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        typeof (self) strongSelf = weakSelf;
#ifdef TESTING
        NSLog(@"TVHeadend does not have api/serverinfo, calling legacy.. (%@)", error.localizedDescription);
#endif
        [strongSelf fetchServerVersionLegacy];
    }];
}

- (void)fetchServerVersionLegacy {
    __weak typeof (self) weakSelf = self;
    [self.jsonClient getPath:@"extjs.html" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSString *response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        [strongSelf handleFetchedServerVersionLegacy:response];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"[TVHServer getVersion]: %@", error.localizedDescription);
    }];
}

- (void)handleFetchedServerVersionLegacy:(NSString*)response {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<title>HTS Tvheadend (.*?)</title>" options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *versionRange = [regex firstMatchInString:response
                                                           options:0
                                                             range:NSMakeRange(0, [response length])];
    if ( versionRange ) {
        NSString *versionString = [response substringWithRange:[versionRange rangeAtIndex:1]];
        self.realVersion = versionString;
    }
}

- (void)setRealVersion:(NSString *)realVersion
{
    _realVersion = realVersion;
    [self.analytics setObjectValue:_realVersion forKey:@"realVersion"];
    NSString *versionString = [_realVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if ([versionString length] > 1) {
        self.version = [versionString substringWithRange:NSMakeRange(0, 2)];
#ifdef TESTING
        NSLog(@"[TVHServer getVersion]: %@", self.version);
#endif
        [self.analytics setObjectValue:self.version forKey:@"version"];
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidLoadVersionNotification
                                                            object:self];
    }
}

#pragma mark fetch capabilities

- (void)fetchCapabilities {
    __weak typeof (self) weakSelf = self;
    [self.jsonClient getPath:@"capabilities" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSError *error;
        NSArray *json = [TVHJsonClient convertFromJsonToArray:responseObject error:&error];
        if( error ) {
            NSLog(@"[TVHServer fetchCapabilities]: error %@", error.description);
            return ;
        }
        _capabilities = json;
#ifdef TESTING
        NSLog(@"[TVHServer capabilities]: %@", _capabilities);
#endif
        [strongSelf.analytics setObjectValue:_capabilities forKey:@"server.capabilities"];
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidLoadCapabilitiesNotification
                                                            object:weakSelf];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"[TVHServer capabilities]: %@", error.localizedDescription);
    }];

}

- (void)fetchConfigSettings {
    __weak typeof (self) weakSelf = self;
    [self.jsonClient getPath:@"config" parameters:@{@"op":@"loadSettings"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSError *error;
        NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseObject error:&error];
        
        if( error ) {
            NSLog(@"[TVHServer fetchConfigSettings]: error %@", error.description);
            return ;
        }
        
        NSArray *entries = [json objectForKey:@"config"];
        NSMutableDictionary *config = [[NSMutableDictionary alloc] init];
        
        [entries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [config setValue:obj forKey:key];
            }];
        }];
        
        strongSelf.configSettings = [config copy];
#ifdef TESTING
        NSLog(@"[TVHServer configSettings]: %@", self.configSettings);
#endif
        [strongSelf.analytics setObjectValue:self.configSettings forKey:@"server.configSettings"];
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidLoadConfigSettingsNotification
                                                            object:weakSelf];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"[TVHServer capabilities]: %@", error.localizedDescription);
    }];
    
}

- (BOOL)isTranscodingCapable {
    if ( self.capabilities ) {
        NSInteger idx = [self.capabilities indexOfObject:@"transcoding"];
        if ( idx != NSNotFound ) {
            // check config settings now
            NSNumber *transcodingEnabled = [self.configSettings objectForKey:@"transcoding_enabled"];
            if ( [transcodingEnabled integerValue] == 1 ) {
                return true;
            }
        }
    }
    return false;
}

#pragma mark TVH Server Details

- (NSString*)htspUrl {
    return [self.settings htspURL];
}

- (NSString*)httpUrl {
    return [self.settings httpURL];
}

@end
