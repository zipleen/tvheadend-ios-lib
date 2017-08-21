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

#import <Expecta/Expecta.h>
#import "OHHTTPStubs/OHHTTPStubs.h"
#import <XCTest/XCTest.h>
#import "TVHTestHelper.h"
#import "TVHEpgStore34.h"
#import "TVHEpgStoreA15.h"
#import "TVHJsonUTF8AutoCharsetResponseSerializer.h"

@interface TVHEpgStoreTests : XCTestCase

@end

@interface TVHEpgStore34 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *epgStore;
- (void)fetchedData:(NSData *)responseData;
@end

@interface TVHEpgStoreA15 (MyPrivateMethodsUsedForTesting)
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
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"testServer"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData* stubData = [TVHTestHelper loadFixture:@"Log.287"];;
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];

    TVHEpgStore34 *tvhe = [[TVHEpgStore34 alloc] initWithStatsEpgName:@"bla" withTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    XCTAssertNotNil(tvhe, @"creating tvepg store object");
    [tvhe downloadEpgList];
    
    expect(tvhe.epgStore).after(5).willNot.beNil();
    expect(tvhe.epgStore.count).after(5).to.equal(1);
    
    XCTAssertTrue( ([tvhe.epgStore count] == 1), @"Failed parsing json data");
    
    TVHEpg *epg = [tvhe.epgStore objectAtIndex:0];
    XCTAssertEqualObjects(epg.title, @"Nacional x Benfica - Primeira Liga", @"epg title doesnt match");
    XCTAssertEqual(epg.channelid, (NSInteger)131, @"epg channel id doesnt match");
    XCTAssertEqualObjects(epg.channel, @"Sport TV 1 Meo", @"channel name does not match" );
    // chicon now gets the channelObject from channelStore, so this is impossible to test =)
    //XCTAssertEqualObjects(epg.chicon, @"https://dl.dropbox.com/u/a/TVLogos/sport_tv1_pt.jpg", @"channel icon does not match" );
    XCTAssertFalse([epg.description isEqualToString:@""], @"description empty");
    XCTAssertEqual(epg.id, (NSInteger)400297, @"epg id does not match" );
    XCTAssertEqual(epg.duration, (NSInteger)8100, @"epg id does not match" );
    XCTAssertEqualObjects(epg.start, [NSDate dateWithTimeIntervalSince1970:1360519200], @"start date does not match" );
    XCTAssertEqualObjects(epg.end, [NSDate dateWithTimeIntervalSince1970:1560527300], @"end date does not match" );
}

- (void)testConvertingAllLogFiles
{
    NSError __autoreleasing *error;
    
    // get a list of "log" files in the test's bundle
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundle.bundlePath error:nil];
    NSPredicate *logPred = [NSPredicate predicateWithFormat:@"self BEGINSWITH 'Log'"];
    NSArray *logFiles = [dirFiles filteredArrayUsingPredicate:logPred];
    
    TVHJsonUTF8AutoCharsetResponseSerializer *serializer = [TVHJsonUTF8AutoCharsetResponseSerializer serializer];
    
    // see if we got any, and if so, test each one
    if ( logFiles ) {
        for ( int index=0; index < logFiles.count; index++ ) {
            NSString *file = [logFiles objectAtIndex:index];
            NSLog(@"processing %@", file);
            NSData *data = [TVHTestHelper loadFixture:file];
            XCTAssertNotNil(data, @"error loading json from file");
            NSDictionary *dict = [serializer responseObjectForResponse:nil data:data error:&error];
            XCTAssertNotNil(dict, @"error processing json");
        }
    }
}

- (void)testConvertFromJsonToObject
{
    NSData *data = [TVHTestHelper loadFixture:@"Log.287.invalid"];
    NSError __autoreleasing *error;
    
    TVHJsonUTF8AutoCharsetResponseSerializer *serializer = [TVHJsonUTF8AutoCharsetResponseSerializer serializer];
    NSDictionary *dict = [serializer responseObjectForResponse:nil data:data error:&error];
    XCTAssertNotNil(dict, @"error processing json");
}

- (void)testConvertFromJsonToObject2
{
    NSData *data = [TVHTestHelper loadFixture:@"Log.epg.utf.invalid"];
    NSError __autoreleasing *error;
    TVHJsonUTF8AutoCharsetResponseSerializer *serializer = [TVHJsonUTF8AutoCharsetResponseSerializer serializer];
    [serializer responseObjectForResponse:nil data:data error:&error];
    XCTAssertNil(error, @"json has no errors? - was this fixed?");
}

@end
