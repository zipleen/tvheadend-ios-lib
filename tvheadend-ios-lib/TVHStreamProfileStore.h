//
//  TVHStreamProfileStore.h
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 25/09/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import "TVHApiClient.h"

@class TVHServer;

@protocol TVHStreamProfileStoreDelegate <NSObject>
@optional
@end

@protocol TVHStreamProfileStore <TVHStreamProfileStoreDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchStreamProfiles;
- (NSArray*)profiles;
- (NSArray*)profilesAsString;
@end
