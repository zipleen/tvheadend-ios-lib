//
//  TVHCometPollStore.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/21/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHCometPollAbstract.h"
#import "TVHServer.h"

@interface TVHCometPollAbstract() {
    BOOL timerStarted;
    BOOL timerActiveWhenSendingToBackground;
}
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSString *boxid;
@property (nonatomic) BOOL debugActive;
@property (nonatomic, strong) NSTimer *timer;
@property (atomic) unsigned int activePolls;
@end

@implementation TVHCometPollAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = self.tvhServer.apiClient;
    
    self.debugActive = false;
    self.activePolls = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    return self;
}

- (void)appWillResignActive:(NSNotification*)note {
    __strong typeof (self) strongSelf = self;
    timerActiveWhenSendingToBackground = timerStarted;
    if ( timerStarted ) {
        [strongSelf stopRefreshingCometPoll];
    }
}

- (void)appWillEnterForeground:(NSNotification*)note {
    __strong typeof (self) strongSelf = self;
    if ( timerActiveWhenSendingToBackground ) {
        [strongSelf startRefreshingCometPoll];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.boxid = nil;
}

- (BOOL)fetchedData:(NSData *)responseData {
    NSError __autoreleasing *error;
    NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseData error:&error];
    if (error) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:TVHDidErrorCometPollNotification
            object:error];
        return false;
    }
    
    NSString *boxid = [json objectForKey:@"boxid"];
    self.boxid = boxid;
    
    NSArray *messages = [json objectForKey:@"messages"];
    for (id obj in messages) {
        NSString *notificationClass = [obj objectForKey:@"notificationClass"];
#ifdef TESTING
        NSLog(@"[Comet Poll Received notificationClass]: %@ {%@}", notificationClass, obj);
        BOOL print = YES;
#endif
        if( [notificationClass isEqualToString:@"subscriptions"] ) {
            [[NSNotificationCenter defaultCenter]
                postNotificationName:TVHStatusSubscriptionStoreReloadNotification
                object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"input_status"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHStatusInputStoreReloadNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"tvAdapter"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHAdapterStoreReloadNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"logmessage"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDidReceiveLogMessageNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"dvbMux"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvbMuxReloadNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"dvrdb"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrStoreReloadNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"autorec"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHAutoStoreReloadNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"dvrentry"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrStoreReloadNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"channels"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHChannelStoreReloadNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
        if( [notificationClass isEqualToString:@"channeltags"] ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHTagStoreReloadNotification
             object:obj];
#ifdef TESTING
            print = NO;
#endif
        }
        
#ifdef TESTING
        if(print) {
            NSLog(@"[CometPollStore log]: %@", obj);
        }
#endif
    }
    
    return true;
}

- (void)toggleDebug {
    
    self.debugActive = !self.debugActive;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.boxid, @"boxid", @"0", @"immediate", nil];
    
    [self.apiClient postPath:@"comet/debug" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        [self timerRefreshCometPoll];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
    }];
    
}

- (void)fetchCometPollStatus {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.boxid, @"boxid", @"0", @"immediate", nil];
    __weak typeof (self) weakSelf = self;
    [self.apiClient postPath:@"comet/poll" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        // sending to main queue so the notification messages are sent in the main queue - and also to unlock the NSLock
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof (self) strongSelf = weakSelf;
            [strongSelf fetchedData:responseObject];
            strongSelf.activePolls = 0;
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        typeof (self) strongSelf = weakSelf;
        strongSelf.activePolls = 0;
#ifdef TESTING
        NSLog(@"[CometPollStore HTTPClient Error]: %@", error.localizedDescription);
#endif
    }];
}

- (void)timerRefreshCometPoll {
    __weak typeof (self) weakSelf = self;
    // the activePoll lock needs to be done in the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.activePolls == 0) {
            self.activePolls = 1;
            
            // but after the lock is done, we want to send the actual "fetch" to a low priority
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                typeof(self) strongSelf = weakSelf;
                [strongSelf fetchCometPollStatus];
            });
        }
    });
}

- (void)startRefreshingCometPoll {
    [self stopRefreshingCometPoll];
#ifdef TESTING
    NSLog(@"[Comet Poll Timer]: Starting comet poll refresh");
#endif
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerRefreshCometPoll) userInfo:nil repeats:YES];
    timerStarted = YES;
}

- (void)stopRefreshingCometPoll {
#ifdef TESTING
    NSLog(@"[Comet Poll Timer]: Stopped comet poll refresh");
#endif
    if ( self.timer ) {
#ifdef TESTING
        NSLog(@"[Comet Poll Timer]: Stopping - invalidating timer..");
#endif
        [self.timer invalidate];
        self.timer = nil;
    }
    timerStarted = NO;
}

- (BOOL)isTimerStarted {
    return timerStarted;
}

- (BOOL)isDebugActive {
    return self.debugActive;
}
@end
