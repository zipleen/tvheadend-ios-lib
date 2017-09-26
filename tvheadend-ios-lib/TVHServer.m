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
@property (nonatomic, strong) TVHPlayStream *playStream;
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
@property (nonatomic, strong) id <TVHConfigNameStore> configNameStore;
@property (nonatomic, strong) id <TVHStatusInputStore> inputStore;
@property (nonatomic, strong) id <TVHNetworkStore> networkStore;
@property (nonatomic, strong) id <TVHStreamProfileStore> streamProfileStore;
@property (nonatomic, strong) NSString *version;     // version like 32, 34, 40 - legacy only!
@property (nonatomic, strong) NSString *realVersion; // real version number, unmodified
@property (nonatomic, strong) NSNumber *apiVersion;  // the new API JSON version
@property (nonatomic) BOOL userHasAdminAccess;
@property (nonatomic, strong) NSArray *capabilities;
@property (nonatomic, strong) NSDictionary *configSettings;
@property (nonatomic, strong) NSTimer *timer;
@property (atomic) BOOL inProcessing;
@end

@implementation TVHServer 

#pragma mark NSNotification

- (void)appWillResignActive:(NSNotification*)note {
    NSLog(@"TVHServer: appWillResignActive");
    [self stopTimer];
}

- (void)appWillEnterForeground:(NSNotification*)note {
    NSLog(@"TVHServer: appWillEnterForeground");
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.channelStore updateChannelsProgress];
            self.inProcessing = NO;
        });
    }
}

#pragma mark init

- (TVHServer*)initWithSettings:(TVHServerSettings*)settings {
    self = [self initWithSettingsButDontInit:settings];
    if (self) {
#ifdef ENABLE_XBMC
        [TVHPlayXbmc sharedInstance];
#endif
#ifdef ENABLE_CHROMECAST
        // in unit tests, the chromecast init crashes. it seems in unit tests the sharedapplication returns nil
        if ([UIApplication sharedApplication] != nil) {
            [TVHPlayChromeCast sharedInstance];
        }
#endif
        [self fetchServerVersion];

        [self.tagStore fetchTagList];
        [self.channelStore fetchChannelList];
        
        [self.statusStore fetchStatusSubscriptions];
        [self.adapterStore fetchAdapters];
        [self.networkStore fetchNetworks];
        [self.inputStore fetchStatusInputs];
        [self.muxStore fetchMuxes];
        [self.serviceStore fetchServices];
        [self.streamProfileStore fetchStreamProfiles];
        
        [self logStore];
        
        [self.configNameStore fetchConfigNames];
        [self fetchConfigSettings];
        [self cometStore];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [self startTimer];
    }
    return self;
}

// settingsInit
- (TVHServer*)initWithSettingsButDontInit:(TVHServerSettings*)settings {
    self = [super init];
    if (self) {
        if ( ! settings ) {
            return nil;
        }
        self.inProcessing = NO;

        self.settings = settings;
        self.version = settings.version;
        self.apiVersion = settings.apiVersion;
        self.userHasAdminAccess = settings.userHasAdminAccess;
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

- (id <TVHConfigNameStore>)configNameStore {
    if( ! _configNameStore ) {
        _configNameStore = [self factory:@"TVHConfigNameStore"];
    }
    return _configNameStore;
}

- (id <TVHStreamProfileStore>)streamProfileStore {
    if( ! _streamProfileStore ) {
        _streamProfileStore = [self factory:@"TVHStreamProfileStore"];
    }
    return _streamProfileStore;
}

- (id <TVHEpgStore>)createEpgStoreWithName:(NSString*)statsName {
    Class myClass = NSClassFromString([@"TVHEpgStore" stringByAppendingString:self.version]);
    if ( !myClass ) {
        myClass = NSClassFromString([@"TVHEpgStore" stringByAppendingString:TVH_LATEST_SUPPORTED_API]);
    }
    
    id <TVHEpgStore> epgStore = [[myClass alloc] initWithStatsEpgName:statsName withTvhServer:self];
    return epgStore;
}

- (NSString*)version {
    // apiVersion has the real HTTP JSON API version - no more guessing
    if ( _apiVersion && [_apiVersion integerValue] > 0 ) {
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
            return @"A12";
        }
    }
    return @"34";
}

- (BOOL)isVersionFour
{
    if (self.apiVersion && [self.apiVersion integerValue] > 0) {
        return true;
    }
    
    return false;
}

- (BOOL)isReady {
    if (!self.jsonClient) {
        return NO;
    }
    return self.jsonClient.readyToUse;
}

- (TVHPlayStream*)playStream {
    if ( ! _playStream ) {
        _playStream = [[TVHPlayStream alloc] initWithTvhServer:self];
    }
    return _playStream;
}

#pragma mark fetch version

- (void)fetchServerVersion {
    __weak typeof (self) weakSelf = self;
    [self.apiClient getPath:@"api/serverinfo" parameters:nil success:^(NSURLSessionDataTask *task, NSDictionary *json) {
        typeof (self) strongSelf = weakSelf;
        
        // this capabilities seems to retrieve a different array from /capabilities
        //strongSelf.capabilities = [json valueForKey:@"capabilities"];
        strongSelf.apiVersion = [json valueForKey:@"api_version"];
        strongSelf.realVersion = [json valueForKey:@"sw_version"];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        typeof (self) strongSelf = weakSelf;
#ifdef TESTING
        NSLog(@"TVHeadend does not have api/serverinfo, calling legacy.. (%@)", error.localizedDescription);
#endif
        [strongSelf fetchServerVersionLegacy];
    }];
}

- (void)fetchServerVersionLegacy {
    __weak typeof (self) weakSelf = self;
    [self.apiClient getPath:@"extjs.html" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSString *response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        [strongSelf handleFetchedServerVersionLegacy:response];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
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

- (void)setRealVersion:(NSString *)realVersion {
    _realVersion = realVersion;
    [self.analytics setObjectValue:_realVersion forKey:@"realVersion"];
    NSString *versionString = [_realVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if ([versionString length] > 1) {
        self.version = [versionString substringWithRange:NSMakeRange(0, 2)];
#ifdef TESTING
        NSLog(@"[TVHServer getVersion]: %@", self.version);
#endif
        [self.analytics setObjectValue:self.version forKey:@"version"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidLoadVersionNotification
                                                                object:self];
        });
    }
}

#pragma mark fetch capabilities

- (void)fetchConfigSettings {
    if (!self.userHasAdminAccess) {
        return;
    }
    __weak typeof (self) weakSelf = self;
    [self.apiClient getPath:@"config" parameters:@{@"op":@"loadSettings"} success:^(NSURLSessionDataTask *task, NSDictionary *json) {
        typeof (self) strongSelf = weakSelf;
        
        NSArray *entries = [json objectForKey:@"config"];
        NSMutableDictionary *config = [[NSMutableDictionary alloc] init];
        
        for (NSDictionary* obj in entries) {
            [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                // ignore satip keys because they might contain uuid which we do not care
                if (![key containsString:@"satip"]) {
                    [config setValue:obj forKey:key];
                }
            }];
        };
        
        strongSelf.configSettings = [config copy];
#ifdef TESTING
        NSLog(@"[TVHServer configSettings]: %@", self.configSettings);
#endif
        [strongSelf.analytics setObjectValue:self.configSettings forKey:@"server.configSettings"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidLoadConfigSettingsNotification
                                                                object:weakSelf];
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"[TVHServer fetchConfigSettings]: %@", error.localizedDescription);
    }];
    
}

#pragma mark TVH Server Details

- (NSString*)htspUrl {
    return [self.settings htspURL];
}

- (NSString*)httpUrl {
    return [self.settings httpURL];
}

@end
