//
//  TVHStatusConnection.h
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 18/04/2018.
//  Copyright (c) 2018 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

@class TVHServer;

@interface TVHStatusConnection : NSObject
@property (nonatomic) NSInteger id;
@property (strong, nonatomic) NSString *server;
@property (nonatomic) NSInteger serverPort;
@property (strong, nonatomic) NSString *peer;
@property (nonatomic) NSInteger peerPort;
@property (nonatomic) NSInteger started;
@property (strong, nonatomic) NSString *type;
- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)updateValuesFromDictionary:(NSDictionary*) values;

- (void)killConnection;
@end
