//
//  TVHEpgStore.h
//  TvhClient
//
//  Created by Luis Fernandes on 02/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHChannel.h"
#import "TVHApiClient.h"


#define TVHEpgStoreReloadNotification @"epgNotificationClassReceived"
#define TVHEpgStoreWillLoadNotification @"willLoadEpg"
#define TVHEpgStoreDidLoadNotification @"didLoadEpg"
#define TVHEpgStoreDidErrorNotification @"didErrorTags"

#define TVHWillRemoveEpgFromRecording @"willRemoveEpgFromRecording"
#define TVHDidSuccessfulyAddEpgToRecording @"didSuccessfulyAddEpgToRecording"

#define MAX_REQUEST_EPG_ITEMS 300 // tvheadend has a limit of how much items you can request at one time
#define DEFAULT_REQUEST_EPG_ITEMS 50 // this is the default query limit on the webUI
#define SECONDS_TO_FETCH_AHEAD_EPG_ITEMS 21600

@class TVHServer;
@class TVHEpgStore;
@class TVHChannel;
@class TVHTag;

@protocol TVHEpgStoreDelegate <NSObject>
- (void)didLoadEpg;
@optional
- (void)didLoadEpgButWillLoadMore;
- (void)willLoadEpg;
- (void)didErrorLoadingEpgStore:(NSError*)error;
@end

@protocol TVHEpgStore <TVHApiClientDelegate>
@property (nonatomic, strong) NSString *filterToProgramTitle;
@property (nonatomic, strong) NSString *filterToChannelName;
@property (nonatomic, strong) NSString *filterToTagName;
@property (nonatomic, strong) NSString *filterToContentTypeId;
@property NSInteger filterStart;
@property NSInteger filterLimit;
@property (nonatomic) BOOL fullTextSearch;

@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, strong) NSString *statsEpgName;
- (id)initWithStatsEpgName:(NSString*)statsEpgName withTvhServer:(TVHServer*)tvhServer;
- (void)appWillEnterForeground:(NSNotification*)note;

- (NSInteger)numberOfRequestedEpgItems;
- (void)downloadAllEpgItems;
- (void)downloadEpgList;
- (void)downloadMoreEpgList;
- (void)clearEpgData;
- (NSArray*)epgStoreItems;
- (NSDictionary*)epgByChannelCopy;
- (NSArray*)channelsOfEpgByChannel;
- (void)setDelegate:(id <TVHEpgStoreDelegate>)delegate;
- (void)removeOldProgramsFromStore;
- (BOOL)isLastEpgFromThePast;
- (void)setFilterToChannel:(TVHChannel *)filterToChannel;
- (void)setFilterToTag:(TVHTag *)filterToTag;
- (NSInteger)totalEventCount;
@end
