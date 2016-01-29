//
//  TVHChannelStore.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/3/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHChannelStoreAbstract.h"
#import "TVHEpg.h"
#import "TVHServer.h"

@interface TVHChannelStoreAbstract ()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) id <TVHEpgStore> currentlyPlayingEpgStore;
@end

@implementation TVHChannelStoreAbstract

- (id <TVHEpgStore>)currentlyPlayingEpgStore {
    if( ! _currentlyPlayingEpgStore ){
        _currentlyPlayingEpgStore = [self.tvhServer createEpgStoreWithName:@"CurrentlyPlaying"];
        [_currentlyPlayingEpgStore setDelegate:self];
        // we can't have the object register the notification, because every channel has one epgStore - that would make every epgStore object update itself!!
        [[NSNotificationCenter defaultCenter] addObserver:_currentlyPlayingEpgStore
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return _currentlyPlayingEpgStore;
}

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    self.filterTag = @"0";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchChannelList)
                                                 name:TVHChannelStoreReloadNotification
                                               object:nil];


    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.channels = nil;
    self.currentlyPlayingEpgStore = nil;
    self.apiClient = nil;
}

- (BOOL)fetchedData:(NSData *)responseData {
    NSError __autoreleasing *error;
    NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseData error:&error];
    if (error) {
        [self signalDidErrorLoadingChannelStore:error];
        return false;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *channels = [[NSMutableArray alloc] initWithCapacity:entries.count];
    
    for (id obj in entries) {
        TVHChannel *channel = [[TVHChannel alloc] initWithTvhServer:self.tvhServer];
        [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [channel setValue:obj forKey:key];
        }];
        [channels addObject:channel];
    }
    
    if ( [self.tvhServer.settings sortChannel] == TVHS_SORT_CHANNEL_BY_NAME ) {
        self.channels =  [[channels copy] sortedArrayUsingSelector:@selector(compareByName:)];
    } else {
        self.channels =  [[channels copy] sortedArrayUsingSelector:@selector(compareByNumber:)];
    }
#ifdef TESTING
    NSLog(@"[Loaded Channels]: %d", (int)[self.channels count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.channels count] forKey:@"channels"];
    [self.currentlyPlayingEpgStore clearEpgData];
    return true;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"POST";
}

- (NSString*)apiPath {
    return @"channels";
}

- (NSDictionary*)apiParameters {
    return @{@"op":@"list"};
}

- (void)fetchChannelList {
    return [self fetchChannelListWithSuccess:nil failure:nil loadEpgForChannels:YES];
}

- (void)fetchChannelListWithSuccess:(ChannelLoadedCompletionBlock)successBlock
                            failure:(ChannelLoadedCompletionBlock)failureBlock
                 loadEpgForChannels:(BOOL)loadEpg
{
    __block NSDate *profilingDate = [NSDate date];
    [self signalWillLoadChannels];
    
    __weak typeof (self) weakSelf = self;
    [self.apiClient doApiCall:self success:^(AFHTTPRequestOperation *operation, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:profilingDate];
        [strongSelf.tvhServer.analytics sendTimingWithCategory:@"Network Profiling"
                                   withValue:time
                                    withName:@"ChannelStore"
                                   withLabel:nil];
#ifdef TESTING
        NSLog(@"[ChannelList Profiling Network]: %f", time);
#endif
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            if ( [strongSelf fetchedData:responseObject] ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (successBlock != nil) {
                        successBlock(self.channels);
                    }
                    if ([strongSelf.delegate respondsToSelector:@selector(didLoadChannels)]) {
                        [strongSelf.delegate didLoadChannels];
                    }
                    
                    [[strongSelf.tvhServer tagStore] signalDidLoadTags];
                    
                    if (loadEpg) {
                        [strongSelf.currentlyPlayingEpgStore downloadEpgList];
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failureBlock != nil) {
                        failureBlock(nil);
                    }
                });
            }
        });
        
       // NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
       // NSLog(@"Request Successful, response '%@'", responseStr);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock != nil) {
            failureBlock(nil);
        }
        [weakSelf signalDidErrorLoadingChannelStore:error];
        NSLog(@"[ChannelList HTTPClient Error]: %@", error.localizedDescription);
    }];
}

#pragma mark EPG delegatee stuff

- (void)didLoadEpg {
    // for each epg
    NSArray *list = [self.currentlyPlayingEpgStore epgStoreItems];
    for (TVHEpg *epg in list) {
        TVHChannel *channel = [self channelWithName:epg.channel];
        [channel addEpg:epg];
    }
    // instead of having this delegate here, channel could send a notification and channel controller
    // could catch it and reload only that line if data was different ?
    [self signalDidLoadChannels];
}

- (void)didErrorLoadingEpgStore:(NSError*)error {
    [self signalDidErrorLoadingChannelStore:error];
}

#pragma mark Controller delegate stuff

- (NSArray*)filteredChannelList {
    return [self filteredChannelList:self.filterTag];
}

- (NSArray*)filteredChannelList:(NSString*)filterTag {
    NSMutableArray *filteredChannels = [[NSMutableArray alloc] initWithCapacity:self.channelCount];
    for (TVHChannel *channel in self.channels) {
        if( [channel hasTag:filterTag] ) {
            [filteredChannels addObject:channel];
        }
    }
    
    if ( [self.tvhServer.settings sortChannel] == TVHS_SORT_CHANNEL_BY_NAME ) {
        return [[filteredChannels copy] sortedArrayUsingSelector:@selector(compareByName:)];
    } else {
        return [[filteredChannels copy] sortedArrayUsingSelector:@selector(compareByNumber:)];
    }
}

- (NSArray*)channelsWithTag:(NSString*)tag {
    if ( [tag isEqualToString:@"0"] ) {
        return [self.channels copy];
    } else {
        return [self filteredChannelList:tag];
    }
}

- (NSArray*)arrayChannels {
    if ( [self.filterTag isEqualToString:@"0"] ) {
        return [self.channels copy];
    } else {
        return [self filteredChannelList];
    }
}

- (NSUInteger)channelCount {
    return self.channels.count;
}

- (TVHChannel*)channelWithName:(NSString*)name {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    NSArray *filteredArray = [self.channels filteredArrayUsingPredicate:predicate];
    if ([filteredArray count] > 0) {
        return [filteredArray objectAtIndex:0];
    }
    return nil;
}

- (TVHChannel*)channelWithId:(NSString*)channelId {
    // not using a predicate because if I find one channel then I'll return it right away
    for (TVHChannel *channel in self.channels) {
        if ( [channel.channelIdKey isEqualToString:channelId] ) {
            return channel;
        }
    }
    return nil;
}

- (void)setDelegate:(id <TVHChannelStoreDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

- (void)signalWillLoadChannels {
    if ([self.delegate respondsToSelector:@selector(willLoadChannels)]) {
        [self.delegate didLoadChannels];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TVHChannelStoreWillLoadNotification
                                                        object:self];
}

- (void)signalDidLoadChannels {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadChannels)]) {
            [self.delegate didLoadChannels];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHChannelStoreDidLoadNotification
                                                            object:self];
    });
}

- (void)signalDidErrorLoadingChannelStore:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(didErrorLoadingChannelStore:)]) {
        [self.delegate didErrorLoadingChannelStore:error];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TVHChannelStoreDidErrorNotification
                                                        object:self];
}

- (void)updateChannelsProgress {
    // 1 - remove old programs, from currentlyPlaying and from each Channel
    [self.currentlyPlayingEpgStore removeOldProgramsFromStore];
    
    // 2 - check if we need to download more programs
    for ( TVHChannel *channel in self.channels ) {
        if ( [channel isLastEpgFromThePast] ) {
            [self.currentlyPlayingEpgStore downloadEpgList];
            break;
        }
    }
    
    // 3 - remove old programs from channels (this should have the previous more programs already added)
    for ( TVHChannel *channel in self.channels ) {
        [channel removeOldProgramsFromStore];
    }
    
    // 4 - signal the refresh of channel data, with updated EPG
    if (self.channels) {
        [self signalDidLoadChannels];
    }
}

@end
