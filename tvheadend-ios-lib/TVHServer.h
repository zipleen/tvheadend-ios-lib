//
//  TVHServer.h
//  TvhClient
//
//  Created by Luis Fernandes on 16/05/2013.
//  Copyright (c) 2013 Luis Fernandes. 
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//


#import "TVHServerSettings.h"
#import "TVHTagStore.h"
#import "TVHChannelStore.h"
#import "TVHEpgStore.h"
#import "TVHDvrStore.h"
#import "TVHAutoRecStore.h"
#import "TVHStatusSubscriptionsStore.h"
#import "TVHStatusConnectionStore.h"
#import "TVHMuxStore.h"
#import "TVHServiceStore.h"
#import "TVHAdaptersStore.h"
#import "TVHStatusInputStore.h"
#import "TVHLogStore.h"
#import "TVHNetworkStore.h"
#import "TVHCometPoll.h"
#import "TVHConfigNameStore.h"
#import "TVHJsonClient.h"
#import "TVHApiClient.h"
#import "TVHModelAnalyticsProtocol.h"
#import "TVHStreamProfileStore.h"
#import "TVHPlayStream.h"

#define TVHDidLoadConfigSettingsNotification @"didLoadTVHConfigSettings"
#define TVHDidLoadCapabilitiesNotification @"didLoadTVHCapabilities"
#define TVHDidLoadVersionNotification @"didLoadTVHVersion"

#define TVH_IMPORTANCE @{@"Important":@"0", @"High":@"1", @"Normal":@"2", @"Low":@"3", @"Unimportant":@"4", @"Not Set":@"-1",@"important":@"0", @"high":@"1", @"normal":@"2", @"low":@"3", @"unimportant":@"4" }

@interface TVHServer : NSObject
@property (nonatomic, strong) TVHServerSettings *settings;
@property (nonatomic, weak) id<TVHModelAnalyticsProtocol> analytics;
- (TVHApiClient*)apiClient;
- (TVHPlayStream*)playStream;
- (id <TVHTagStore>)tagStore;
- (id <TVHChannelStore>)channelStore;
- (id <TVHDvrStore>)dvrStore;
- (id <TVHAutoRecStore>)autorecStore;
- (id <TVHStatusSubscriptionsStore>)statusStore;
- (id <TVHAdaptersStore>)adapterStore;
- (id <TVHMuxStore>)muxStore;
- (id <TVHServiceStore>)serviceStore;
- (id <TVHStatusConnectionStore>)connectionStore;
- (TVHLogStore*)logStore;
- (id <TVHCometPoll>)cometStore;
- (id <TVHConfigNameStore>)configNameStore;
- (id <TVHStatusInputStore>)inputStore;
- (id <TVHNetworkStore>)networkStore;
- (id <TVHStreamProfileStore>)streamProfileStore;
- (NSNumber*)apiVersion;
- (NSString*)version;
- (NSString*)realVersion;
- (BOOL)userHasAdminAccess;
- (BOOL)isVersionFour;
- (BOOL)isReady;
- (BOOL)hasCorrectAuthenticationMethods;
- (BOOL)fixAuthSettings;

- (TVHServer*)initWithSettings:(TVHServerSettings*)settings;
- (TVHServer*)initWithSettingsButDontInit:(TVHServerSettings*)settings;
- (id <TVHEpgStore>)createEpgStoreWithName:(NSString*)statsName;
- (void)fetchServerVersion;
- (void)cancelAllOperations;
- (NSString*)htspUrl;
- (NSString*)httpUrl;

@end
