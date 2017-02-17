//
//  TVHEpgStore.h
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/10/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHEpgStore.h"

@class TVHServer;
@class TVHEpgStore;

@interface TVHEpgStoreAbstract : NSObject <TVHEpgStore, TVHApiClientDelegate>
@property (nonatomic, strong) NSString *filterToProgramTitle;
@property (nonatomic, strong) NSString *filterToChannelName;
@property (nonatomic, strong) NSString *filterToTagName;
@property (nonatomic, strong) NSString *filterToContentTypeId;
@property NSInteger filterStart;
@property NSInteger filterLimit;

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
@end
