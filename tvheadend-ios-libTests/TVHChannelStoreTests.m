//
//  TVHChannelStoreTests.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/22/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Expecta/Expecta.h>
#import <XCTest/XCTest.h>
#import "TVHTestHelper.h"
#import "TVHChannelStore34.h"
#import "TVHChannel.h"
#import "OHHTTPStubs/OHHTTPStubs.h"

@interface TVHChannelStoreTests : XCTestCase

@end

@interface TVHChannelStore34 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *channels;
- (void)fetchedData:(NSData *)responseData;
@end

@implementation TVHChannelStoreTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
  [super tearDown];
  [OHHTTPStubs removeAllStubs];
}

- (void)testJsonChannelParsing
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"testServer"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData* stubData = [TVHTestHelper loadFixture:@"Log.channels"];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    TVHServer *mockServer = [TVHTestHelper mockTVHServer:@"34"];
    TVHChannelStore34 *store = [[TVHChannelStore34 alloc] initWithTvhServer:mockServer];
    XCTAssertNotNil(store, @"creating channel store object");
    
    [store fetchChannelList];
    
    [Expecta setAsynchronousTestTimeout:2];
    
    expect(store.channels).after(3).willNot.beNil();
    expect(store.channels.count).to.equal(7);
    
    XCTAssertTrue( ([store.channels count] == 7), @"channel count does not match");
    
    TVHChannel *channel = [store.channels lastObject];
    XCTAssertEqualObjects(channel.name, @"VH", @"tag name does not match");
    XCTAssertEqualObjects(channel.imageUrl, @"http:///vh.jpg", @"tag name does not match");
    XCTAssertEqual(channel.number, 143, @"channel number does not match");
    XCTAssertEqual(channel.chid, (NSInteger)60, @"channel ID does not match");
    NSArray *tags = [[NSArray alloc] initWithObjects:@"8", @"53", nil];
    XCTAssertEqualObjects(channel.tags, tags, @"channel tags does not match");
    
    channel = [store.channels objectAtIndex:0];
    XCTAssertEqualObjects(channel.name, @"AXX", @"tag name does not match");
    XCTAssertEqualObjects(channel.imageUrl, @"http:///ajpg", @"tag name does not match");
    XCTAssertEqual(channel.number, 60, @"channel number does not match");
    XCTAssertEqual(channel.chid, (NSInteger)15, @"channel ID does not match");
    
    channel = [store.channels objectAtIndex:2];
    XCTAssertEqualObjects(channel.name, @"AXX HD", @"tag name does not match");
    XCTAssertEqualObjects(channel.imageUrl, nil, @"tag name does not match");
    XCTAssertEqual(channel.number, 0, @"channel number does not match");
    tags = [[NSArray alloc] initWithObjects:@"16", @"19", @"8", nil];
    XCTAssertEqualObjects(channel.tags, tags, @"channel tags does not match");
    XCTAssertEqual(channel.chid, (NSInteger)114, @"channel ID does not match");

}

@end
