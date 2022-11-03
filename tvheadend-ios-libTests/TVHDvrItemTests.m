//
//  TVHDvrItemTests.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 11/10/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import <Expecta/Expecta.h>
#import "OHHTTPStubs/OHHTTPStubs.h"
#import "TVHTestHelper.h"
#import "TVHDvrItem.h"
#import "TVHDvrStoreA15.h"
#import "TVHServerSettings.h"
#import "TVHServer.h"
#import <XCTest/XCTest.h>

@interface TVHDvrItemTests : XCTestCase

@end

@interface TVHDvrStoreA15 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *dvrItems;
- (void)fetchDvrItemsFromServer:(NSString*)url withType:(NSInteger)type start:(NSInteger)start limit:(NSInteger)limit;
@end

@implementation TVHDvrItemTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
  [super tearDown];
  [OHHTTPStubs removeAllStubs];
}

- (void)testBrokenUtfCharacter {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"testServer"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData* stubData = [TVHTestHelper loadFixture:@"Log.246.grid_finished.json"];;
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"text/x-json; charset=UTF-8"}];
    }];
    
    TVHDvrStoreA15 *tvhe = [[TVHDvrStoreA15 alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    XCTAssertNotNil(tvhe, @"creating dvr store store object");
    [tvhe fetchDvrItemsFromServer:@"api/dvr/entry/grid_finished" withType:RECORDING_FINISHED start:0 limit:120];
    
    expect(tvhe.dvrItems).after(10).willNot.beNil();
    expect(tvhe.dvrItems.count).after(10).to.equal(120);
    
    XCTAssertEqual(tvhe.dvrItems.count, 120);
    
    // @todo this is broken :( anyone knows how to correctly convert this ? - https://github.com/zipleen/tvheadend-iphone-client/issues/246
    //XCTAssertEqualObjects([tvhe.dvrItems[0] disp_title], @"Предложението");
}

- (void)testFullTitle {
    TVHDvrItem *dvr = [[TVHDvrItem alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    
    // only disp_title
    dvr.disp_title = @"my title";
    XCTAssertEqualObjects(dvr.fullTitle, @"my title");
    dvr.title = @"no override";
    XCTAssertEqualObjects(dvr.fullTitle, @"my title");
    
    // only title
    dvr = [[TVHDvrItem alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    dvr.title = @"other title";
    XCTAssertEqualObjects(dvr.fullTitle, @"other title");
    
    // disp_title and empty subtitle
    dvr = [[TVHDvrItem alloc] initWithTvhServer:[TVHTestHelper mockTVHServer:@"34"]];
    dvr.disp_title = @"my 2nd title";
    dvr.disp_subtitle = @"";
    XCTAssertEqualObjects(dvr.fullTitle, @"my 2nd title");
    
    // disp_title and subtitle and episode
    dvr.episode = @"episode";
    XCTAssertEqualObjects(dvr.fullTitle, @"my 2nd title (episode)");
}

- (void)testPlayStream {
    
    expect([self dvrStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"" streamProfile:@""] withUrl:@"dvrfile/6e8765f02c9394b97e4b9364f9549d1c" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/dvrfile/6e8765f02c9394b97e4b9364f9549d1c");
    
    expect([self dvrStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"" streamProfile:@""] withUrl:@"dvrfile/6e8765f02c9394b97e4b9364f9549d1c" withInternalPlayer:YES]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/dvrfile/6e8765f02c9394b97e4b9364f9549d1c");
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

- (NSString*)dvrStreamUrl:(TVHServerSettings*)settings withUrl:(NSString*)url withInternalPlayer:(BOOL)internalPlayer {
    TVHServer *server = [[TVHServer alloc] initWithSettingsButDontInit:settings];
    TVHDvrItem *dvr = [[TVHDvrItem alloc] initWithTvhServer:server];
    [dvr setUrl:url];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSString *streamUrl;
    [server.playStream streamObject:dvr withInternalPlayer:internalPlayer completion:^(NSString *rstreamUrl) {
        streamUrl = rstreamUrl;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return streamUrl;
}

@end
