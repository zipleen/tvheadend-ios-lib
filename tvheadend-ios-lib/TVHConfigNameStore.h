//
//  TVHConfigNameStore.h
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 25/09/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import "TVHApiClient.h"

@class TVHServer;

@protocol TVHConfigNameDelegate <NSObject>
@optional
@end

@protocol TVHConfigNameStore <TVHConfigNameDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchConfigNames;
- (NSString*)nameForId:(NSString*)uuid;
- (NSString*)idForName:(NSString*)name;
- (NSArray*)configNamesAsString;
@end
