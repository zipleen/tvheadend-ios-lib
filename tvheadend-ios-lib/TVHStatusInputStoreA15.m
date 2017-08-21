//
//  TVHStatusInputStore40.m
//  TvhClient
//
//  Created by zipleen on 10/12/13.
//  Copyright (c) 2013 zipleen. All rights reserved.
//

#import "TVHStatusInputStoreA15.h"
#import "TVHServer.h"

@interface TVHStatusInputStoreA15()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *inputs;
@end

@implementation TVHStatusInputStoreA15

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSubscriptionNotification:)
                                                 name:TVHStatusInputStoreReloadNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchStatusInputs)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.inputs = nil;
}

- (void)receiveSubscriptionNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:TVHStatusInputStoreReloadNotification]) {
        NSDictionary *message = (NSDictionary*)[notification object];
        
        if ( [[message objectForKey:@"reload"] intValue] == 1 ) {
            [self fetchStatusInputs];
        }
        
        for (TVHStatusInput* obj in self.inputs) {
            if ([[message objectForKey:@"uuid"] isEqualToString:obj.uuid]) {
                [obj updateValuesFromDictionary:message];
            }
        }
        
        [self signalDidLoadStatusInputs];
    }
}

- (BOOL)fetchedData:(NSDictionary *)json {
        
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *inputs = [[NSMutableArray alloc] initWithCapacity:entries.count];
    
    for (id obj in entries) {
        TVHStatusInput *statusInput = [[TVHStatusInput alloc] init];
        [statusInput updateValuesFromDictionary:obj];
        
        [inputs addObject:statusInput];
    }
    
    self.inputs = [inputs copy];
    
#ifdef TESTING
    NSLog(@"[Loaded Status Input]: %d", (int)[self.inputs count]);
#endif
    [self.tvhServer.analytics setIntValue:[self.inputs count] forKey:@"statusInput"];
    return true;
}

#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return @"api/status/inputs";
}

- (NSDictionary*)apiParameters {
    return nil;
}

- (void)fetchStatusInputs {
    if (!self.tvhServer.userHasAdminAccess) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    
    [self signalWillLoadStatusInputs];
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if ( [strongSelf fetchedData:responseObject] ) {
                [strongSelf signalDidLoadStatusInputs];
            }
        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf signalDidErrorStatusInputStore:error];
        NSLog(@"[Status Input HTTPClient Error]: %@", error.localizedDescription);
    }];
}

- (TVHStatusInput *)objectAtIndex:(NSUInteger) row {
    if ( row < [self.inputs count] ) {
        return [self.inputs objectAtIndex:row];
    }
    return nil;
}

- (int)count {
    return (int)[self.inputs count];
}

- (void)setDelegate:(id <TVHStatusInputDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

#pragma mark Signal delegates

- (void)signalDidLoadStatusInputs {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didLoadStatusInputs)]) {
            [self.delegate didLoadStatusInputs];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusInputStoreDidLoadNotification
                                                            object:self];
    });
}

- (void)signalWillLoadStatusInputs {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(willLoadStatusInputs)]) {
            [self.delegate willLoadStatusInputs];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusInputStoreWillLoadNotification
                                                            object:self];
    });
}

- (void)signalDidErrorStatusInputStore:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(didErrorStatusInputStore:)]) {
            [self.delegate didErrorStatusInputStore:error];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TVHStatusInputStoreDidErrorNotification
                                                            object:error];
    });
}

@end
