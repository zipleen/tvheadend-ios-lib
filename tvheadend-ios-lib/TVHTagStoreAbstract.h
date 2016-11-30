//
//  TVHTagStore.h
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/9/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHApiClient.h"
#import "TVHTagStore.h"
#import "TVHTag.h"

@class TVHServer;

@interface TVHTagStoreAbstract : NSObject <TVHApiClientDelegate, TVHTagStore>
@property (nonatomic, weak) TVHServer *tvhServer;
@property (nonatomic, weak) id <TVHTagStoreDelegate> delegate;
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (NSArray*)tags;
- (TVHTag*)tagWithIdKey:(NSString*)idKey;
- (void)fetchTagList;
- (void)signalDidLoadTags;
@end
