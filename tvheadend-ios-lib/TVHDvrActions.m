//
//  TVHDvrActions.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/28/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHDvrActions.h"
#import "TVHJsonClient.h"
#import "TVHDvrStore.h"
#import "TVHServer.h"

@implementation TVHDvrActions

+ (void)doDvrAction:(NSString*)action withId:(NSInteger)idint withIdName:(NSString*)idName withConfigName:(NSString*)configName withTvhServer:(TVHServer*)tvhServer {
    TVHJsonClient *httpClient = [tvhServer jsonClient];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%lu", (unsigned long)idint ],
                                   idName,
                                   action,
                                   @"op",
                                   configName,
                                   @"configName",nil];
    
    [httpClient postPath:@"dvr" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSError __autoreleasing *error;
        NSDictionary *json = [TVHJsonClient convertFromJsonToObject:responseObject error:&error];
        if( error ) {
#ifdef TESTING
            NSLog(@"[DVR ACTIONS ERROR processing JSON]: %@", error.localizedDescription);
#endif
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrActionDidErrorNotification
             object:error];
        }
        NSInteger success = [[json objectForKey:@"success"] intValue];
        if ( success ) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrActionDidSucceedNotification
             object:action];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidSuccessfulyAddEpgToRecording
                                                                object:[NSNumber numberWithInt:(int)idint]];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrActionDidReturnErrorNotification
             object:action];
        }
        
        // reload dvr
        id <TVHDvrStore> store = [tvhServer dvrStore];
        [store fetchDvr];
        
        //NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        //NSLog(@"Request Successful, response '%@'", responseStr);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#ifdef TESTING
        NSLog(@"[DVR ACTIONS ERROR]: %@", error.localizedDescription);
#endif
        [[NSNotificationCenter defaultCenter]
         postNotificationName:TVHDvrActionDidErrorNotification
         object:error];
    }];

}

+ (void)addRecording:(NSInteger)eventId withConfigName:(NSString*)configName withTvhServer:(TVHServer*)tvhServer  {
    [TVHDvrActions doDvrAction:@"recordEvent" withId:eventId withIdName:@"eventId" withConfigName:configName withTvhServer:tvhServer];
}

+ (void)cancelRecording:(NSInteger)entryId withTvhServer:(TVHServer*)tvhServer {
    [TVHDvrActions doDvrAction:@"cancelEntry" withId:entryId withIdName:@"entryId" withConfigName:nil withTvhServer:tvhServer];
}

+ (void)deleteRecording:(NSInteger)entryId withTvhServer:(TVHServer*)tvhServer {
    [TVHDvrActions doDvrAction:@"deleteEntry" withId:entryId withIdName:@"entryId" withConfigName:nil withTvhServer:tvhServer];
}

+ (void)addAutoRecording:(NSInteger)eventId withConfigName:(NSString*)configName withTvhServer:(TVHServer*)tvhServer  {
    [TVHDvrActions doDvrAction:@"recordSeries" withId:eventId withIdName:@"eventId" withConfigName:configName withTvhServer:tvhServer];
}

@end
