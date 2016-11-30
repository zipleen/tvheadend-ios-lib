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
#import "TVHEpgStoreA15.h"

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
    NSData *data = [TVHTestHelper loadFixture:@"Log.epg.maury.txt"]; //Log.287
	XCTAssertNotNil(data, @"error loading json from file");
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

- (void)testConvertFromJsonToObject
{
	NSError __autoreleasing *error;
    NSData *data = [TVHTestHelper loadFixture:@"Log.epg.maury.txt"]; //Log.287.invalid ir EPG
	//NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	//NSString *path = [bundle pathForResource:@"Log.epg.maury" ofType:@"txt"];
	//NSString *content = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:&error];
	//NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
	
	XCTAssertNotNil(data, @"error loading json from file");
	
    NSDictionary *dict = [TVHJsonClient convertFromJsonToObject:data error:&error];
    XCTAssertNotNil(dict, @"error processing json");
}

- (void)testConvertingAllLogFiles
{
	NSError __autoreleasing *error;

	// get a list of "log" files in the test's bundle
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundle.bundlePath error:nil];
	NSPredicate *logPred = [NSPredicate predicateWithFormat:@"self BEGINSWITH 'Log'"];
	NSArray *logFiles = [dirFiles filteredArrayUsingPredicate:logPred];
	
	// see if we got any, and if so, test each one
	if ( logFiles ) {
		for ( int index=0; index<logFiles.count; index++ ) {
			NSString *file = [logFiles objectAtIndex:index];
			NSData *data = [TVHTestHelper loadFixture:file]; //Log.287.invalid ir EPG
			XCTAssertNotNil(data, @"error loading json from file");
			NSDictionary *dict = [TVHJsonClient convertFromJsonToObject:data error:&error];
			XCTAssertNotNil(dict, @"error processing json");
		}
	}
}

- (void)testConvertFromJsonToObject2
{
    NSData *data = [TVHTestHelper loadFixture:@"Log.epg.utf.invalid"];
	XCTAssertNotNil(data, @"error loading json from file");
    NSError __autoreleasing *error;
    [TVHJsonClient convertFromJsonToObject:data error:&error];
    XCTAssertNil(error, @"json has no errors? - was this fixed?");
}

@end
