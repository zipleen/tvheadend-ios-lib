//
//  TVHEpgTests.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 11/10/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TVHEpg.h"
#import "TVHTestHelper.h"

@interface TVHEpgTests : XCTestCase

@end

@implementation TVHEpgTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFullTitle {
    TVHEpg *epg = [[TVHEpg alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    
    // only disp_title
    epg.title = @"my title";
    XCTAssertEqualObjects(epg.fullTitle, @"my title ");
    
    epg.episode = @"episode";
    epg.episodeOnscreen = @"do not show";
    XCTAssertEqualObjects(epg.fullTitle, @"my title episode");
    
    epg = [[TVHEpg alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    epg.title = @"my title";
    epg.episodeOnscreen = @"s01e01";
    XCTAssertEqualObjects(epg.fullTitle, @"my title s01e01");
    
    epg = [[TVHEpg alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    epg.title = @"my title";
    epg.episodeNumber = 1;
    epg.seasonNumber = 1;
    XCTAssertEqualObjects(epg.fullTitle, @"my title 1/1");
}

@end
