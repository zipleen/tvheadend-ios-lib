//
//  TVHAutoDiscovery.h
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 11/02/2016.
//  Copyright © 2016 zipleen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TVHAutoDiscoveryDelegate <NSObject>
@optional
- (void)autoDiscoveryServersFound;
- (void)stoppedAutoDiscovery;
@end

@interface TVHAutoDiscovery : NSObject
@property (nonatomic, weak) id <TVHAutoDiscoveryDelegate> delegate;

- (instancetype)initWithDelegate:(id<TVHAutoDiscoveryDelegate>)delegate ;
- (NSArray*)foundServers;
@end
