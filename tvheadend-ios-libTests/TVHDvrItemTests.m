//
//  TVHDvrItemTests.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 11/10/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import "TVHTestHelper.h"
#import "TVHDvrItem.h"
#import <XCTest/XCTest.h>

@interface TVHDvrItemTests : XCTestCase

@end

@implementation TVHDvrItemTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFullTitle {
    TVHDvrItem *dvr = [[TVHDvrItem alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    
    // only disp_title
    dvr.disp_title = @"my title";
    XCTAssertEqualObjects(dvr.fullTitle, @"my title");
    dvr.title = @"no override";
    XCTAssertEqualObjects(dvr.fullTitle, @"my title");
    
    // only title
    dvr = [[TVHDvrItem alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    dvr.title = @"other title";
    XCTAssertEqualObjects(dvr.fullTitle, @"other title");
    
    // disp_title and empty subtitle
    dvr = [[TVHDvrItem alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    dvr.disp_title = @"my 2nd title";
    dvr.disp_subtitle = @"";
    XCTAssertEqualObjects(dvr.fullTitle, @"my 2nd title");
    
    // disp_title and subtitle and episode
    dvr.episode = @"episode";
    XCTAssertEqualObjects(dvr.fullTitle, @"my 2nd title (episode)");
}


@end
