//
//  TVHEpgStoreTests.m
//  TVHeadend iPhone Client
//
//  Created by zipleen on 2/16/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <XCTest/XCTest.h>
#import "TVHTestHelper.h"
#import "TVHEpgStore34.h"

@interface TVHEpgStoreTests : XCTestCase

@end

@interface TVHEpgStore34 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *epgStore;
- (void)fetchedData:(NSData *)responseData;
@end


@implementation TVHEpgStoreTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testJsonCharacterBug
{
    NSData *data = [TVHTestHelper loadFixture:@"Log.287"];
    TVHEpgStore34 *tvhe = [[TVHEpgStore34 alloc] init];
    XCTAssertNotNil(tvhe, @"creating tvepg store object");
    [tvhe fetchedData:data];
    XCTAssertTrue( ([tvhe.epgStore count] == 1), @"Failed parsing json data");
    
    TVHEpg *epg = [tvhe.epgStore objectAtIndex:0];
    XCTAssertEqualObjects(epg.title, @"Nacional x Benfica - Primeira Liga", @"epg title doesnt match");
    XCTAssertEqual(epg.channelid, (NSInteger)131, @"epg channel id doesnt match");
    XCTAssertEqualObjects(epg.channel, @"Sport TV 1 Meo", @"channel name does not match" );
    XCTAssertEqualObjects(epg.chicon, @"https://dl.dropbox.com/u/a/TVLogos/sport_tv1_pt.jpg", @"channel name does not match" );
    XCTAssertFalse([epg.description isEqualToString:@""], @"description empty");
    XCTAssertEqual(epg.id, (NSInteger)400297, @"epg id does not match" );
    XCTAssertEqual(epg.duration, (NSInteger)8100, @"epg id does not match" );
    XCTAssertEqualObjects(epg.start, [NSDate dateWithTimeIntervalSince1970:1360519200], @"start date does not match" );
    XCTAssertEqualObjects(epg.end, [NSDate dateWithTimeIntervalSince1970:1360527300], @"end date does not match" );
}



@end
