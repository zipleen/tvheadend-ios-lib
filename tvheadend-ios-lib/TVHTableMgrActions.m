//
//  TVHTableMgrActions.m
//  TvhClient
//
//  Created by Luis Fernandes on 3/14/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHTableMgrActions.h"

@implementation TVHTableMgrActions

+ (void)doTableMgrAction:(NSString*)action withApiClient:(TVHApiClient*)httpClient inTable:(NSString*)table withEntries:(id)entries {
    NSString *stringEntries;
    
    if ( [entries isKindOfClass:[NSString class]] ) {
        stringEntries = [NSString stringWithFormat:@"\"%@\"",entries];
    } else {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:entries
                                                           options:0 
                                                             error:nil];
        stringEntries = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"[%@]", stringEntries],
                            @"entries",
                            action,
                            @"op",
                            table,
                            @"table",nil];
    
    [httpClient postPath:@"tablemgr" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
                 postNotificationName:TVHDidSuccessedTableMgrActionNotification
                 object:action];
        });
        
#ifdef TESTING
        // there are weird crashes when doing the initWithData:responseObject. I don't actually need it, so I'm delegating this to #testing!
        // according to a stackoverflow, this might be because responseObject is already a NSString. In my case, from the crashes, it seems to be a NSDictionary?
        if (responseObject == nil) {
            return;
        }
        
        NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"Request Successful, response '%@'", responseStr);
#endif
        // reload dvr
        /*TVHAutoRecStore *store = [[TVHSingletonServer sharedServerInstance] autorecStore];
        [store fetchDvrAutoRec];
        
        id<TVHDvrStore> dvrStore = [[TVHSingletonServer sharedServerInstance] dvrStore];
        [dvrStore fetchDvr];*/
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
#ifdef TESTING
        NSLog(@"[TableMgr ACTIONS ERROR]: %@", error.localizedDescription);
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"didErrorTableMgrAction"
             object:error];
        });
    }];
    
}

@end
