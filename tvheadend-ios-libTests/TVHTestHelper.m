//
//  TVHTestHelper.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/22/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHTestHelper.h"
#import "TVHServer.h"
#import "TVHServerSettings.h"

@implementation TVHTestHelper

+ (NSData *)loadFixture:(NSString *)name
{
    NSBundle *unitTestBundle = [NSBundle bundleForClass:[self class]];
    NSString *pathForFile    = [unitTestBundle pathForResource:name ofType:nil];
    NSData   *data           = [[NSData alloc] initWithContentsOfFile:pathForFile];
    return data;
}

+ (TVHServer*)mockTVHServer:(NSString*)version
{
    TVHServerSettings *settings = [[TVHServerSettings alloc] initWithSettings:@{TVHS_SERVER_NAME:@"",
                                                                                TVHS_IP_KEY:@"testServer",
                                                                                TVHS_PORT_KEY:@"9981",
                                                                                TVHS_HTSP_PORT_KEY:@"9982",
                                                                                TVHS_USERNAME_KEY:@"",
                                                                                TVHS_PASSWORD_KEY:@"",
                                                                                TVHS_USE_HTTPS:@"",
                                                                                TVHS_SERVER_WEBROOT:@"",
                                                                                TVHS_SSH_PF_HOST:@"",
                                                                                TVHS_SSH_PF_PORT:@"",
                                                                                TVHS_SSH_PF_USERNAME:@"",
                                                                                TVHS_SSH_PF_PASSWORD:@"",
                                                                                TVHS_SERVER_VERSION:version}];
    settings.autoStartPolling = YES;
    TVHServer *server = [[TVHServer alloc] initWithSettingsButDontInit:settings];
    server.analytics = nil;
    return server;
}

@end
