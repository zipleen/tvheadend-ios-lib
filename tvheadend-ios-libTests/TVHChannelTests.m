//
//  TVHChannelTests.m
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
#import "OHHTTPStubs/OHHTTPStubs.h"
#import <XCTest/XCTest.h>
#import "TVHTestHelper.h"
#import "TVHChannel.h"
#import "TVHEpg.h"
#import "TVHEpgStore34.h"
#import "TVHEpgStoreA15.h"
#import "TVHChannelEpg.h"
#import "TVHServer.h"
#import "TVHJsonUTF8AutoCharsetResponseSerializer.h"

@interface TVHEpgStore34 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *epgStore;
- (void)fetchedData:(NSDictionary *)responseData;
- (BOOL)addEpgItemToStore:(TVHEpg*)epgItem;
@end

@interface TVHEpgStoreA15 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *epgStore;
- (void)fetchedData:(NSData *)responseData;
@end


@interface TVHChannelTests : XCTestCase <TVHChannelDelegate>

@end

@interface TVHChannel (MyPrivateMethodsUsedForTesting) 
@property (nonatomic, strong) NSMutableArray *channelEpgDataByDay;
@property (nonatomic, strong) id <TVHEpgStore> restOfEpgStore;
@end

@implementation TVHChannelTests 

- (void)tearDown
{
  [super tearDown];
  [OHHTTPStubs removeAllStubs];
}

- (TVHChannel*)channel {
    TVHChannel *channel = [[TVHChannel alloc] init];
    
    return channel;
}

- (TVHEpg*)epg {
    TVHEpg *epg = [[TVHEpg alloc] init];
    [epg updateValuesFromDictionary:@{
        @"channelid":@27,
        @"id":@442521,
        @"title":@"Jornal das 8",
        @"description":@"Episodio 1.\n",
        @"duration":@6120,
        @"start":@1361563200,
        @"end":@1361569320 }];
    return epg;
}

- (void)didLoadEpgChannel{}

- (void)testNextPrograms {
    TVHChannel *channel = [self channel];
    [channel setUuid:@"123"];
    
    TVHEpg *epg = [self epg];
    epg.id = 1;
    [epg setTitle:@"Before 2"];
    [epg setStart:[NSDate dateWithTimeIntervalSinceNow:-1800]];
    [epg setEnd:[NSDate dateWithTimeIntervalSinceNow:-600]];
    [channel addEpg:epg];
    
    epg = [self epg];
    epg.id = 2;
    [epg setTitle:@"Before 1"];
    [epg setStart:[NSDate dateWithTimeIntervalSinceNow:-600]];
    [epg setEnd:[NSDate dateWithTimeIntervalSinceNow:-60]];
    [channel addEpg:epg];
    
    epg = [self epg];
    epg.id = 3;
    [epg setTitle:@"Currently running"];
    [epg setStart:[NSDate dateWithTimeIntervalSinceNow:-60]];
    [epg setEnd:[NSDate dateWithTimeIntervalSinceNow:600]];
    [channel addEpg:epg];
    
    epg = [self epg];
    epg.id = 4;
    [epg setTitle:@"Next 1"];
    [epg setStart:[NSDate dateWithTimeIntervalSinceNow:60]];
    [epg setEnd:[NSDate dateWithTimeIntervalSinceNow:1800]];
    [channel addEpg:epg];
    
    epg = [self epg];
    epg.id = 5;
    [epg setTitle:@"Next 2"];
    [epg setStart:[NSDate dateWithTimeIntervalSinceNow:1800]];
    [epg setEnd:[NSDate dateWithTimeIntervalSinceNow:2500]];
    [channel addEpg:epg];
    
    NSArray *nextPrograms = [channel nextPrograms:3];
    expect(nextPrograms.count).to.equal(3);
    expect([nextPrograms[0] title]).to.equal(@"Currently running");
    expect([nextPrograms[1] title]).to.equal(@"Next 1");
    expect([nextPrograms[2] title]).to.equal(@"Next 2");
}

- (void)testDuplicateEpg {
    
    TVHChannel *channel = [self channel];
    TVHEpg *epg = [self epg];
    
    [channel addEpg:epg];
    TVHChannelEpg *chepg = [channel.channelEpgDataByDay objectAtIndex:0];
    XCTAssertTrue( ([chepg.programs count] == 1), @"epg not inserted");
    
    [channel addEpg:epg];
    chepg = [channel.channelEpgDataByDay objectAtIndex:0];
    XCTAssertTrue( ([chepg.programs count] == 1), @"programs == %lu should be 1", (unsigned long)[chepg.programs count]);

    [channel addEpg:epg];
    chepg = [channel.channelEpgDataByDay objectAtIndex:0];
    XCTAssertTrue( ([chepg.programs count] == 1), @"programs == %lu should be 1", (unsigned long)[chepg.programs count]);
}

- (void)testDuplicateEpgFromFetchMorePrograms {
    NSDate *thisDateInTime = [NSDate dateWithTimeIntervalSince1970:1361644400];
    [Timecop freezeWithDate:thisDateInTime block:^{
        NSData *data = [TVHTestHelper loadFixture:@"Log.oneChannelEpg"];
        NSError __autoreleasing *error;
        TVHJsonUTF8AutoCharsetResponseSerializer *serializer = [TVHJsonUTF8AutoCharsetResponseSerializer serializer];
        
        TVHEpgStore34 *store = [[TVHEpgStore34 alloc ] init];
        [store fetchedData:[serializer responseObjectForResponse:nil data:data error:&error]];
        
        TVHChannel *channel = [self channel];
        TVHEpg *epg = [self epg];
        
        [channel setDelegate:self];
        [channel setRestOfEpgStore:store];
        [channel addEpg:epg];
        TVHChannelEpg *chepg = [channel.channelEpgDataByDay objectAtIndex:0];
        XCTAssertTrue( ([chepg.programs count] == 1), @"epg not inserted");
        
        [channel didLoadEpg];
        chepg = [channel.channelEpgDataByDay objectAtIndex:0];
        XCTAssertTrue( ([chepg.programs count] == 4), @"programs == %lu should be 4", (unsigned long)[chepg.programs count]);
        
        [channel didLoadEpg];
        chepg = [channel.channelEpgDataByDay objectAtIndex:0];
        XCTAssertTrue( ([chepg.programs count] == 4), @"programs == %lu should be 4", (unsigned long)[chepg.programs count]);
        
    }];
}
- (void)testDuplicateEpgInRemoveOldPrograms {
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"testServer"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData* stubData = [TVHTestHelper loadFixture:@"Log.oneChannelEpg"];;
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    NSDate *thisDateInTime = [NSDate dateWithTimeIntervalSince1970:1361644400];
    [Timecop freezeWithDate:thisDateInTime block:^{
        TVHEpgStore34 *tvhe = [[TVHEpgStore34 alloc] initWithStatsEpgName:@"bla" withTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
        XCTAssertNotNil(tvhe, @"creating tvepg store object");
        [tvhe downloadEpgList];
        
        expect(tvhe.epgStore).after(5).willNot.beNil();
        expect(tvhe.epgStore.count).after(5).to.equal(19);
        
        TVHEpg *epg = [[TVHEpg alloc] initWithTvhServer:tvhe.tvhServer];
        
        // here is an epg of yesterday, so it gets removed from the remove old programs
        NSDate *dateO = [NSDate dateWithTimeIntervalSince1970:1361644400];
        NSTimeInterval aTimeInterval = [dateO timeIntervalSinceReferenceDate] + 86400 * -1;
        [epg setValue:[NSNumber numberWithInteger:[[NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval] timeIntervalSince1970]] forKey:@"start"];
        [epg setValue:[NSNumber numberWithInteger:[[NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval + 500] timeIntervalSince1970]] forKey:@"end"];
        epg.channelid = 27;
        epg.id = 123;
        [tvhe addEpgItemToStore:epg];
        
        XCTAssertEqual(tvhe.epgStore.count, 20);
        NSArray *epgOfChannel27 = [tvhe.epgByChannelCopy objectForKey:@"27"];
        XCTAssertEqual([epgOfChannel27 count], 20);
        
        [tvhe addEpgItemToStore:epg];
        XCTAssertEqual(tvhe.epgStore.count, 20);
        
        [tvhe removeOldProgramsFromStore];
        
        XCTAssertEqual(tvhe.epgStore.count, 19);
        
        // the bug is in epg of each channel
        // it is still going to be 20, because we are not removing the old programs from each channel - however it cannot be 40 :D
        epgOfChannel27 = [tvhe.epgByChannelCopy objectForKey:@"27"];
        XCTAssertEqual([epgOfChannel27 count], 20);
    }];
}

- (void)testRemovingLastEpgOfTheDay {
    TVHChannel *channel = [self channel];
    TVHEpg *epg = [self epg];
    
    [channel addEpg:epg];
    TVHChannelEpg *chepg = [channel.channelEpgDataByDay objectAtIndex:0];
    XCTAssertTrue( ([chepg.programs count] == 1), @"epg not inserted");
    
    // we now have a channel with 1 epg in it
    [channel removeOldProgramsFromStore];
    
    XCTAssertTrue( ([chepg.programs count] == 0), @"epg day was not removed when last epg got removed");
}


- (void)testSortByNumber {
    TVHChannel *channel1 = [self channel];
    TVHChannel *channel2 = [self channel];
    TVHChannel *channelNoNumber = [self channel];
    
    channel1.number = 1;
    channel2.number = 2;
    
    XCTAssertEqual(NSOrderedAscending, [channel1 compareByNumber:channel2]);
    XCTAssertEqual(NSOrderedAscending, [channel2 compareByNumber:channelNoNumber]);
    XCTAssertEqual(NSOrderedDescending, [channelNoNumber compareByNumber:channel2]);
    XCTAssertEqual(NSOrderedSame, [channel1 compareByNumber:channel1]);
    XCTAssertEqual(NSOrderedSame, [channelNoNumber compareByNumber:channelNoNumber]);

}

- (void)testSortByName {
    TVHChannel *channel1 = [self channel];
    TVHChannel *channel2 = [self channel];
    TVHChannel *channel3 = [self channel];
    TVHChannel *channel4 = [self channel];
    
    channel1.name = @"A a first channel";
    channel2.name = @"a b second channel";
    channel3.name = @"B third channel";
    channel4.name = @"A c second channel";
    
    // A a > a b
    XCTAssertEqual(NSOrderedAscending, [channel1 compareByName:channel2]);
    // A > B
    XCTAssertEqual(NSOrderedAscending, [channel1 compareByName:channel3]);
    // a > B
    XCTAssertEqual(NSOrderedAscending, [channel2 compareByName:channel3]);
    
    // a b > A c
    XCTAssertEqual(NSOrderedAscending, [channel2 compareByName:channel4]);
}

- (void)testHtspUrl {
    TVHServerSettings *settings = [[TVHServerSettings alloc] initWithSettings:@{
                                                                               TVHS_HTSP_PORT_KEY: @"1111",
                                                                               TVHS_IP_KEY: @"something",
                                                                               TVHS_USERNAME_KEY: @""
                                                                               }];
    
    TVHServer *server = [[TVHServer alloc] initWithSettingsButDontInit:settings];
    
    TVHChannel *channel = [[TVHChannel alloc] initWithTvhServer:server];
    channel.uuid = @"ad3b0c90ee951c38ac6f5f8b6452fb3c";
    NSLog(@"->%@", channel.htspStreamURL);
    XCTAssertTrue([channel.htspStreamURL isEqualToString:@"htsp://something:1111/tags/0/269237165.ts"]);
    expect(channel.htspStreamURL).to.equal(@"htsp://something:1111/tags/0/269237165.ts");
}

- (void)testStreamUrl {
    // base + https
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"80" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://banana/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://banana:9981/stream/channel/12345");
    // webroot
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"443" username:@"" password:@"" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://banana/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"4443" username:@"" password:@"" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://banana:4443/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"443" username:@"" password:@"" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://banana/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://banana:9981/webroot/stream/channel/12345");
    
    // with basic user + pass
    // base + https
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"80" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://basicuser:basicpass@banana1/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://basicuser:basicpass@banana1:9981/stream/channel/12345");
    // webroot
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://basicuser:basicpass@banana1:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"443" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://basicuser:basicpass@banana1/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"4443" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://basicuser:basicpass@banana1:4443/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345");
    
    // with spaces characters user + pass
    // base + https
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"80" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"81" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:81/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    // webroot
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"443" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"4543" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:4543/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"443" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"4543" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:4543/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345");
    
    // with weird characters user + pass
    // base + https
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"80" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    // webroot
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"443" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"4643" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:4643/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"443" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"3443" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:3443/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/webroot/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/webroot/stream/channel/12345");
    
    // https default ports remove 443
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"80" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"http://banana/stream/channel/12345");
    expect([self channelStreamUrl:[self settingsForIp:@"banana" port:@"443" username:@"" password:@"" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345"]).to.equal(@"https://banana/stream/channel/12345");
    
    
}

- (TVHServerSettings*)settingsForIp:(NSString*)ip port:(NSString*)port username:(NSString*)username password:(NSString*)password https:(NSString*)useHttps webroot:(NSString*)webroot streamProfile:(NSString*)profile {
    return [[TVHServerSettings alloc] initWithSettings:@{TVHS_SERVER_NAME:@"somename",
                                                         TVHS_IP_KEY:ip,
                                                         TVHS_PORT_KEY:port,
                                                         TVHS_HTSP_PORT_KEY:@"9982",
                                                         TVHS_USERNAME_KEY:username,
                                                         TVHS_PASSWORD_KEY:password,
                                                         TVHS_USE_HTTPS:useHttps,
                                                         TVHS_SERVER_WEBROOT:webroot,
                                                         TVHS_VLC_NETWORK_LATENCY:@"999",
                                                         TVHS_VLC_DEINTERLACE: @"0",
                                                         TVHS_SSH_PF_HOST:@"",
                                                         TVHS_SSH_PF_PORT:@"",
                                                         TVHS_SSH_PF_USERNAME:@"",
                                                         TVHS_SSH_PF_PASSWORD:@"",
                                                         TVHS_SERVER_VERSION:@"A15",
                                                         TVHS_API_VERSION:@15,
                                                         TVHS_ADMIN_ACCESS:@1,
                                                         TVHS_STREAM_PROFILE:profile
                                                         }];
}

- (NSString*)channelStreamUrl:(TVHServerSettings*)settings withChannelUUID:(NSString*)uuid {
    TVHServer *server = [[TVHServer alloc] initWithSettingsButDontInit:settings];
    TVHChannel *channel = [[TVHChannel alloc] initWithTvhServer:server];
    [channel setUuid:uuid];
    return channel.streamURL;
}

- (void)testPlayStreamWithChannel {
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"80" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana:9981/stream/channel/12345");
    // webroot
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"" password:@"" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"1443" username:@"" password:@"" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana:1443/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"" password:@"" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana:9981/webroot/stream/channel/12345");
    
    // with basic user + pass
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"80" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1:9981/stream/channel/12345");
    // webroot
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"443" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"443" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345");
    
    // with spaces characters user + pass
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"80" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    // webroot
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345");
    
    // with weird characters user + pass
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"80" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    // webroot
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"webroot" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/webroot/stream/channel/12345");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@"s"  webroot:@"/webroot/" streamProfile:@""] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/webroot/stream/channel/12345");
    
    // ********* with profile ! ************
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@"matroska"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/stream/channel/12345?profile=matroska");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"80" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"" streamProfile:@"weirdé char@cters"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/stream/channel/12345?profile=weird%C3%A9%20char%40cters");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"" streamProfile:@"pass"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana:9981/stream/channel/12345?profile=pass");
    // webroot
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"webroot" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"" password:@"" https:@"s"  webroot:@"webroot" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"" password:@"" https:@"s"  webroot:@"webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@""  webroot:@"/webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://banana:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"" password:@"" https:@"s"  webroot:@"/webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://banana:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    
    // with basic user + pass
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"80" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    // webroot
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"webroot" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"443" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"webroot" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"443" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@""  webroot:@"/webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana1" port:@"9981" username:@"basicuser" password:@"basicpass" https:@"s"  webroot:@"/webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://basicuser:basicpass@banana1:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    
    // with spaces characters user + pass
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"80" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    // webroot
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"webroot" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"webroot" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"443" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@""  webroot:@"/webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"/webroot/" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/webroot/stream/channel/12345?profile=some%20profile%20with%20spaces");
    
    // with weird characters user + pass
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/stream/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"80" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:NO]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana/stream/channel/12345?profile=some%20profile%20with%20spaces");
    
    // for internal player
    // with weird characters user + pass
    // base + https
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:YES]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana:9981/playlist/channel/12345?profile=some%20profile%20with%20spaces");
    expect([self streamUrlForChannel:[self settingsForIp:@"banana" port:@"80" username:@"mé@!%?" password:@"%?@{s0m!$4!#$%&/()=?*\"^|" https:@""  webroot:@"" streamProfile:@"some profile with spaces"] withChannelUUID:@"12345" withInternalPlayer:YES]).to.equal(@"http://m%C3%A9%40!%25%3F:%25%3F%40%7Bs0m!$4!%23$%25&%2F()=%3F*%22%5E%7C@banana/playlist/channel/12345?profile=some%20profile%20with%20spaces");
}

- (NSString*)streamUrlForChannel:(TVHServerSettings*)settings withChannelUUID:(NSString*)uuid withInternalPlayer:(BOOL)internalPlayer {
    TVHServer *server = [[TVHServer alloc] initWithSettingsButDontInit:settings];
    TVHChannel *channel = [[TVHChannel alloc] initWithTvhServer:server];
    [channel setUuid:uuid];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSString *streamUrl;
    [server.playStream streamObject:channel withInternalPlayer:internalPlayer completion:^(NSString *rstreamUrl) {
        streamUrl = rstreamUrl;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return streamUrl;
}

@end
