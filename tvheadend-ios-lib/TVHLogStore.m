//
//  TVHLogStore.m
//  TvhClient
//
//  Created by Luis Fernandes on 09/03/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHLogStore.h"
#import "TVHJsonClient.h"

#define MAXLOGLINES 500

@interface TVHLogStore()
@property (nonatomic, strong) NSMutableArray *logLines;
@end

@implementation TVHLogStore

- (NSMutableArray*)logLines {
    if ( ! _logLines ) {
        _logLines = [[NSMutableArray alloc] init];
    }
    return _logLines;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveDebugLogNotification:)
                                                 name:TVHDidReceiveLogMessageNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.logLines = nil;
}

- (void)addLogLine:(NSString*) line {
    if ( [self.logLines count] > MAXLOGLINES ) {
        [self.logLines removeObjectAtIndex:0];
    }
    [self.logLines addObject:line];
}

- (void)receiveDebugLogNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:TVHDidReceiveLogMessageNotification]) {
        NSDictionary *message = (NSDictionary*)[notification object];
        
        NSString *log = [message objectForKey:@"logtxt"];
        [self addLogLine:log];
        [self signalDidLoadLog];
        
        // catch special types of logtxt messages!
        // 2017-11-01 21:05:32.613 webui: Couldn't start streaming /stream/channel/cec58b26c3aa18423ff95f535dc2e635, No free adapter
        if ([log containsString:@", No free adapter"]) {
            [self signalNoFreeAdapters:log];
        }
        
        // "2017-11-01 20:28:52.024 descrambler: cannot decode packets for service \"bla\"";
        if ([log containsString:@"descrambler: cannot decode packets for service"]) {
            [self signalNoDescramble:log];
        }
    }
}

- (NSArray*)filteredLogLines {
    if ( !self.filter || [self.filter length] == 0 ) {
        return [self.logLines copy];
    }
    NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", self.filter];
    NSArray *logLinesFiltered = [self.logLines filteredArrayUsingPredicate:sPredicate];
    return logLinesFiltered;
}

- (NSArray*)arrayLogLines {
    return [self filteredLogLines];
}

- (void)clearLog {
    [self.logLines removeAllObjects];
}

- (void)setDelegate:(id <TVHLogDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

- (void)signalDidLoadLog {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadLog)]) {
            [self.delegate didLoadLog];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidLoadLog
                                                            object:self];
    });
}

- (void)signalNoFreeAdapters:(NSString*)log {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidReceiveCouldNotStartStreamingNoFreeAdapter
                                                            object:log];
    });
}

- (void)signalNoDescramble:(NSString*)log {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidReceiveNotAbleToDescramble
                                                            object:log];
    });
}

@end
