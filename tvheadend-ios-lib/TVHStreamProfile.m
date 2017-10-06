//
//  TVHStreamProfile.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 25/09/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import "TVHStreamProfile.h"

@implementation TVHStreamProfile

- (void)setName:(NSString *)name {
    NSAssert([name isKindOfClass:[NSString class]], @"name is not a nsstring");
    _name = name;
}

- (NSString*)description {
    return self.name;
}

- (BOOL)isEqual: (id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    TVHStreamProfile *otherCast = other;
    return [self.name isEqualToString:otherCast.name];
}

@end
