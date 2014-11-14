//
//  TVHServerTests.m
//  TvhClient
//
//  Created by Luis Fernandes on 7/21/13.
//  Copyright (c) 2013 Luis Fernandes. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TVHTestHelper.h"
#import "TVHServer.h"

@interface TVHServerTests : XCTestCase

@end

@interface TVHServer (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *realVersion;
//@property (nonatomic, strong) NSArray *capab4ilities;
- (void)handleFetchedServerVersionLegacy:(NSString*)response;
@end


@implementation TVHServerTests

- (void)testServerVersions {
    TVHServer *server = [TVHTestHelper mockTVHServer:@"34"];
    NSData *data = [TVHTestHelper loadFixture:@"extjs.html"];
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [server handleFetchedServerVersionLegacy:response];
    
    XCTAssertEqualObjects([server realVersion], @"3.5.232~g7ac5542-dirty", @"version 3.5.232~g7ac5542-dirty not correctly detected");
    XCTAssertEqualObjects([server version], @"34", @"version 3.5.232~g7ac5542-dirty not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend 3.5.232~g7ac5542-dirty</title>"];
    XCTAssertEqualObjects([server realVersion], @"3.5.232~g7ac5542-dirty", @"lonely version 3.5.232~g7ac5542-dirty not correctly detected");
    XCTAssertEqualObjects([server version], @"34", @"lonely version 3.5.232~g7ac5542-dirty not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend 3.4.27</title>"];
    XCTAssertEqualObjects([server realVersion], @"3.4.27", @"lonely version 3.4.27 not correctly detected");
    XCTAssertEqualObjects([server version], @"34", @"3.4.27 not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend 3.3</title>"];
    XCTAssertEqualObjects([server realVersion], @"3.3", @"lonely version 3.3 not correctly detected");
    XCTAssertEqualObjects([server version], @"34", @"3.3 not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend 3.2.444-ffff</title>"];
    XCTAssertEqualObjects([server realVersion], @"3.2.444-ffff", @"lonely version 3.2.444-ffff not correctly detected");
    XCTAssertEqualObjects([server version], @"32", @"3.2.444-ffff not detected as 3.2");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend 3.0.fe3222</title>"];
    XCTAssertEqualObjects([server realVersion], @"3.0.fe3222", @"lonely version 3.0.fe3222 not correctly detected");
    XCTAssertEqualObjects([server version], @"32", @"3.0.fe3222 not detected as 3.2");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend 2.9.x</title>"];
    XCTAssertEqualObjects([server realVersion], @"2.9.x", @"lonely version 3.0.fe3222 not correctly detected");
    XCTAssertEqualObjects([server version], @"34", @"2.9.x not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend -gt535535</title>"];
    XCTAssertEqualObjects([server realVersion], @"-gt535535", @"lonely version -gt535535 not correctly detected");
    XCTAssertEqualObjects([server version], @"34", @"-gt535535 not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"HTS Tvheadend -gt535535"];
    XCTAssertEqualObjects([server version], @"34", @"invalid not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@""];
    XCTAssertEqualObjects([server version], @"34", @"empty not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>"];
    XCTAssertEqualObjects([server version], @"34", @"empty not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"HTS Tvheadend"];
    XCTAssertEqualObjects([server version], @"34", @"empty not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"</title>"];
    XCTAssertEqualObjects([server version], @"34", @"empty not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend</title>"];
    XCTAssertEqualObjects([server version], @"34", @"empty not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend </title>"];
    XCTAssertEqualObjects([server version], @"34", @"empty not detected as 3.4");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend 3.9.255~gbfa033d</title>"];
    XCTAssertEqualObjects([server realVersion], @"3.9.255~gbfa033d", @"lonely version 3.9.255~gbfa033d not correctly detected");
    XCTAssertEqualObjects([server version], @"A12", @"3.9.255~gbfa033d not detected as 4.0");
    
    [server handleFetchedServerVersionLegacy:@"<title>HTS Tvheadend 4.0.0</title>"];
    XCTAssertEqualObjects([server realVersion], @"4.0.0", @"lonely version 4.0.0 not correctly detected");
    XCTAssertEqualObjects([server version], @"A12", @"4.0.0 not detected as 4.0");
}

@end
