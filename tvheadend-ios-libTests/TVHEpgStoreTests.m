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
#import "TVHServer.h"
#import "TVHChannelStoreA15.h"

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

@interface TVHChannelStoreA15 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *channels;
- (void)fetchChannelListWithSuccess:(ChannelLoadedCompletionBlock)successBlock failure:(ChannelLoadedCompletionBlock)failureBlock loadEpgForChannels:(BOOL)loadEpg;
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

- (void)testChannelsOfEpgByChannel
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:@"http://testServer:9981/api/epg/events/grid?limit=300&start=0"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData* stubData = [TVHTestHelper loadFixture:@"Log.sampleNormal.epg"];;
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:@"http://testServer:9981/channels"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData* stubData = [TVHTestHelper loadFixture:@"Log.sampleNormal.channels"];;
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    TVHServer* server = [TVHTestHelper mockTVHServer:@"A15"];
    TVHChannelStoreA15 *channelStore = (TVHChannelStoreA15*)server.channelStore;
    [channelStore fetchChannelListWithSuccess:nil failure:nil loadEpgForChannels:NO];
    expect(channelStore.channels).after(10).willNot.beNil();
    expect(channelStore.channels.count).after(10).to.equal(44);
    
    NSDate *thisDateInTime = [NSDate dateWithTimeIntervalSince1970:1510601634];
    [Timecop freezeWithDate:thisDateInTime block:^{
        TVHEpgStoreA15 *tvhe = [[TVHEpgStoreA15 alloc] initWithStatsEpgName:@"bla" withTvhServer:server];
        [tvhe downloadEpgList];
        
        expect(tvhe.epgStore).after(5).willNot.beNil();
        expect(tvhe.epgStore.count).after(5).to.equal(300);
        
        XCTAssertTrue( ([tvhe.epgStore count] == 300), @"Failed parsing json data");
        
        NSArray* channelsFromEpg = tvhe.channelsOfEpgByChannel;
        
        expect(channelsFromEpg).toNot.beNil();
        expect(channelsFromEpg.count).to.equal(35);
    }];
    
    
}

- (void)testEpgSummaryBug
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"testServer"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData* stubData = [TVHTestHelper loadFixture:@"Epg.summary.marcel"];;
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"text/x-json"}];
    }];
    
    TVHEpgStore34 *tvhe = [[TVHEpgStore34 alloc] initWithStatsEpgName:@"bla" withTvhServer:[TVHTestHelper mockTVHServer:@"A15"]];
    XCTAssertNotNil(tvhe, @"creating tvepg store object");
    [tvhe downloadEpgList];
    
    expect(tvhe.epgStore).after(5).willNot.beNil();
    expect(tvhe.epgStore.count).after(5).to.equal(1);
    
    XCTAssertTrue( ([tvhe.epgStore count] == 1), @"Failed parsing json data");
    
    TVHEpg *epg = [tvhe.epgStore objectAtIndex:0];
    XCTAssertEqualObjects(epg.title, @"Tennis", @"epg title doesnt match");
    XCTAssertEqualObjects(epg.channelIdKey, @"a94b93f2560712070b458ce5ff9d5251", @"epg channel id doesnt match");
    XCTAssertEqualObjects(epg.channelName, @"SPORT1+", @"channel name does not match" );
    XCTAssertEqualObjects(epg.description, @"Übertragung * Novak Djokovic will bei den BNP Paribas Masters in Paris seinen Titel verteidigen. Im vergangenen Jahr setzte er sich im Finale gegen Andy Murray mit 6:2, 6:4 durch. Das Turnier der 1000er Kategorie hat einen festen Platz im internationalen Terminkalender, insgesamt geht es bei dem Wettbewerb auf Hartplatz um ein Preisgeld von 3,7 Millionen Euro. Das prestigeträchtige Turnier findet in Palais Omnisports in Bercy statt.");
    XCTAssertEqualObjects(epg.summary, @"ATP World Tour Masters 1000 summary");
    
    XCTAssertEqual(epg.eventId, (NSInteger)138901, @"epg id does not match" );
    XCTAssertEqualObjects(epg.start, [NSDate dateWithTimeIntervalSince1970:1677908000], @"start date does not match" );
    XCTAssertEqualObjects(epg.end, [NSDate dateWithTimeIntervalSince1970:1677929600], @"end date does not match" );
    
}

@end
