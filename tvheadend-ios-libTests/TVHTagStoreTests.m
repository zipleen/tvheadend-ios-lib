//
//  TVHTagStoreTests.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/22/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <XCTest/XCTest.h>
#import "TVHTestHelper.h"
#import "TVHTagStore34.h"
#import "TVHTag.h"
#import "TVHJsonUTF8AutoCharsetResponseSerializer.h"

@interface TVHTagStoreTests : XCTestCase

@end

@interface TVHTagStore34 (MyPrivateMethodsUsedForTesting)

@property (nonatomic, strong) NSArray *tags;
- (void)fetchedData:(NSData *)responseData;
@end

@implementation TVHTagStoreTests

- (void)tearDown {
    [super tearDown];
}

- (void)testJsonTagsParsing {
    NSData *data = [TVHTestHelper loadFixture:@"Log.tags"];
    NSError __autoreleasing *error;
    TVHJsonUTF8AutoCharsetResponseSerializer *serializer = [TVHJsonUTF8AutoCharsetResponseSerializer serializer];
    
    TVHTagStore34 *store = [[TVHTagStore34 alloc] init];
    XCTAssertNotNil(store, @"creating tvhtag store object");
    [store fetchedData:[serializer responseObjectForResponse:nil data:data error:&error]];
    XCTAssertTrue( ([store.tags count] == 13+1), @"tag count does not match");
    
    TVHTag *tag = [store.tags lastObject];
    XCTAssertEqualObjects(tag.name, @"Z", @"tag name does not match");
    XCTAssertEqual(tag.id, (NSInteger)8, @"tag id doesnt match");
    
    tag = [store.tags objectAtIndex:0];
    XCTAssertEqualObjects(tag.name, @"All Channels", @"tag name does not match");
    XCTAssertEqual(tag.id, (NSInteger)0, @"tag id doesnt match");
    
    tag = [store.tags objectAtIndex:2];
    XCTAssertEqualObjects(tag.name, @"Desenhos Animados", @"tag name does not match");
    XCTAssertEqual(tag.id, (NSInteger)55, @"tag id doesnt match");
    XCTAssertEqualObjects(tag.icon, @"http://infantil.png", @"tag id doesnt match");

}

- (void)testJsonTagsParsingDuplicate {
    [self testJsonTagsParsing];
    [self testJsonTagsParsing];
}

@end
