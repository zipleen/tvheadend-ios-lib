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
@property (nonatomic, weak) TVHJsonClient *jsonClient;
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
    self.jsonClient = [self.tvhServer jsonClient];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchCometPollStatus)
                                                 name:TVHDoFetchCometStatusNotification
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
    [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *notificationClass = [obj objectForKey:@"notificationClass"];
#ifdef TESTING
        //NSLog(@"[Comet Poll Received notificationClass]: %@ {%@}", notificationClass, obj);
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
    }];
    
    return true;
}

- (void)toggleDebug {
    
    self.debugActive = !self.debugActive;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.boxid, @"boxid", @"0", @"immediate", nil];
    
    [self.jsonClient postPath:@"comet/debug" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self fetchCometPollStatus];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
    
}

- (void)fetchCometPollStatus {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.boxid, @"boxid", @"0", @"immediate", nil];
    
    if ( self.activePolls < 1 ) {
        self.activePolls++;
        __weak typeof (self) weakSelf = self;
        [[self.jsonClient proxyQueueNamed:@"cometQueue"] postPath:@"comet/poll" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            typeof (self) strongSelf = weakSelf;
            if ( [strongSelf fetchedData:responseObject] ) {
                self.activePolls--;
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            self.activePolls--;
#ifdef TESTING
            NSLog(@"[CometPollStore HTTPClient Error]: %@", error.localizedDescription);
#endif
        }];
    }
}

- (void)timerRefreshCometPoll {
    if ( self.activePolls < 1 ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDoFetchCometStatusNotification
                                                            object:nil];
    }
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
