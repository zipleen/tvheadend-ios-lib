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
- (void)fetchedData:(NSData *)responseData;
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

@interface TVHEpgStore34 (MyPrivateMethodsUsedForTesting)
- (void)fetchedData:(NSData *)responseData;
@end

@implementation TVHChannelTests 

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
}

- (void)testDuplicateEpgInRemoveOldPrograms {
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"testServer"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData* stubData = [TVHTestHelper loadFixture:@"Log.oneChannelEpg"];;
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    TVHEpgStore34 *tvhe = [[TVHEpgStore34 alloc] initWithStatsEpgName:@"bla" withTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    XCTAssertNotNil(tvhe, @"creating tvepg store object");
    [tvhe downloadEpgList];
    
    expect(tvhe.epgStore).after(5).willNot.beNil();
    expect(tvhe.epgStore.count).after(5).to.equal(19);
    
    TVHEpg *epg = [[TVHEpg alloc] initWithTvhServer:tvhe.tvhServer];
    
    // here is an epg of yesterday, so it gets removed from the remove old programs
    NSDate *dateO = [NSDate new];
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
@end
