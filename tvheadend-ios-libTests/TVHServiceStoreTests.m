//
//  TVHStatusSubscriptionsStoreTests.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 14/08/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import <Expecta/Expecta.h>
#import "OHHTTPStubs/OHHTTPStubs.h"
#import <XCTest/XCTest.h>
#import "TVHTestHelper.h"
#import "TVHServerSettings.h"
#import "TVHServer.h"
#import "TVHService.h"
#import "TVHServiceStoreA15.h"
#import "TVHJsonUTF8AutoCharsetResponseSerializer.h"

@interface TVHServiceStoreTests : XCTestCase

@end

@interface TVHServiceStoreA15 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *services;
- (void)fetchedServiceData:(NSData *)responseData;
@end


@implementation TVHServiceStoreTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLoadingBigServicesJson {
    NSData *data = [TVHTestHelper loadFixture:@"Log.services.mine"];
    NSError __autoreleasing *error;
    TVHJsonUTF8AutoCharsetResponseSerializer *serializer = [TVHJsonUTF8AutoCharsetResponseSerializer serializer];
    
    //[self measureBlock:^{
        TVHServiceStoreA15 *services = [[TVHServiceStoreA15 alloc] init];
        XCTAssertNotNil(services, @"creating tvepg store object");
        
        [services fetchedServiceData:[serializer responseObjectForResponse:nil data:data error:&error]];
        XCTAssertTrue( ([services.services count] == 29448), @"Failed parsing json data");
    //}];
    
}

- (void)testPlayStream {
    
    expect([self serviceStreamUrl:[self settingsForIp:@"banana" port:@"9981" username:@"my user" password:@"my pass with spaces" https:@"s"  webroot:@"" streamProfile:@""] withUUID:@"d6e8765f02c9394b97e4b9364f9549d1c" withInternalPlayer:NO]).to.equal(@"https://my%20user:my%20pass%20with%20spaces@banana:9981/stream/service/d6e8765f02c9394b97e4b9364f9549d1c");
    
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

- (NSString*)serviceStreamUrl:(TVHServerSettings*)settings withUUID:(NSString*)uuid withInternalPlayer:(BOOL)internalPlayer {
    TVHServer *server = [[TVHServer alloc] initWithSettingsButDontInit:settings];
    TVHService *service = [[TVHService alloc] initWithTvhServer:server];
    [service setUuid:uuid];
    return [server.playStream streamUrlForObject:service withInternalPlayer:internalPlayer];
}

@end
