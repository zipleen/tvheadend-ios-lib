//
//  TVHPlayStreamTests.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 01/04/2018.
//  Copyright © 2018 zipleen. All rights reserved.
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

@interface TVHPlayStream(Private)
- (NSString*)fixUrlComponents:(NSString*)url;
@end;

@interface TVHPlayStreamTests : XCTestCase <TVHChannelDelegate>

@end

@implementation TVHPlayStreamTests

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

- (void)testFixHttpsUrl {
    TVHServer *serverHttps = [[TVHServer alloc] initWithSettingsButDontInit:[self settingsForIp:@"banana" port:@"443" username:@"user" password:@"pass" https:@"s"  webroot:@"" streamProfile:@""]];
   
    expect([serverHttps.playStream fixUrlComponents:@"http://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:443/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    expect([serverHttps.playStream fixUrlComponents:@"https://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:443/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    
    TVHServer *serverHttp = [[TVHServer alloc] initWithSettingsButDontInit:[self settingsForIp:@"banana" port:@"443" username:@"user" password:@"pass" https:@""  webroot:@"" streamProfile:@""]];
    
    expect([serverHttp.playStream fixUrlComponents:@"http://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"http://banana:443/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    
    serverHttps = [[TVHServer alloc] initWithSettingsButDontInit:[self settingsForIp:@"banana" port:@"123" username:@"user" password:@"pass" https:@"s"  webroot:@"" streamProfile:@""]];
    
    expect([serverHttps.playStream fixUrlComponents:@"http://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:123/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    expect([serverHttps.playStream fixUrlComponents:@"https://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:123/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    
    serverHttps = [[TVHServer alloc] initWithSettingsButDontInit:[self settingsForIp:@"banana" port:@"123" username:@"user" password:@"pass" https:@"s"  webroot:@"/tttt" streamProfile:@""]];
    
    expect([serverHttps.playStream fixUrlComponents:@"http://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:123/tttt/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    expect([serverHttps.playStream fixUrlComponents:@"https://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:123/tttt/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    expect([serverHttps.playStream fixUrlComponents:@"https://banana/tttt/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:123/tttt/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    
    serverHttps = [[TVHServer alloc] initWithSettingsButDontInit:[self settingsForIp:@"banana" port:@"123" username:@"user" password:@"pass" https:@"s"  webroot:@"tttt" streamProfile:@""]];
    
    expect([serverHttps.playStream fixUrlComponents:@"http://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:123/tttt/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    expect([serverHttps.playStream fixUrlComponents:@"https://banana/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:123/tttt/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
    expect([serverHttps.playStream fixUrlComponents:@"https://banana/tttt/stream/channelid/1231231231231231221312323122312312321231&profile=pass"]).to.equal(@"https://banana:123/tttt/stream/channelid/1231231231231231221312323122312312321231&profile=pass");
}

@end
