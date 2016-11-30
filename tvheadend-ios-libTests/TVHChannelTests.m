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

#import <XCTest/XCTest.h>
#import "TVHTestHelper.h"
#import "TVHChannel.h"
#import "TVHEpg.h"
#import "TVHEpgStore34.h"
#import "TVHChannelEpg.h"


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
    TVHEpgStore34 *store = [[TVHEpgStore34 alloc ] init];
    [store fetchedData:data];
    
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


@end
