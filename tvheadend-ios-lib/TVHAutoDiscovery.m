//
//  TVHAutoDiscovery.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 11/02/2016.
//  Copyright © 2016 zipleen. All rights reserved.
//

#import "TVHAutoDiscovery.h"
#include <arpa/inet.h>
#include "TVHServerSettings.h"

#define SERVICE_TYPE_HTTP @"_http._tcp."
#define SERVICE_TYPE_HTSP @"_htsp._tcp."
#define DOMAIN_NAME @"local"
#define DISCOVER_TIMEOUT 5.0f

@interface TVHAutoDiscovery() <NSNetServiceDelegate,  NSNetServiceBrowserDelegate> {
    NSMutableArray *services;
    NSMutableArray *foundServices;
    BOOL searching;
    NSNetServiceBrowser *netServiceBrowserHttp;
    NSNetServiceBrowser *netServiceBrowserHtsp;
    NSTimer *timerHttp;
    NSTimer *timerHtsp;
}
@end

@implementation TVHAutoDiscovery

- (instancetype)init {
    self = [super init];
    if (self) {
        services = [[NSMutableArray alloc] init];
        foundServices = [[NSMutableArray alloc] init];
        netServiceBrowserHttp = [[NSNetServiceBrowser alloc] init];
        netServiceBrowserHtsp = [[NSNetServiceBrowser alloc] init];
    }
    return self;
}

- (instancetype)initWithDelegate:(id<TVHAutoDiscoveryDelegate>)delegate {
    self = [self init];
    if (self) {
        self.delegate = delegate;
        [self startDiscover];
    }
    return self;
}

- (void)dealloc {
    services = nil;
    foundServices = nil;
    netServiceBrowserHttp = nil;
    netServiceBrowserHtsp = nil;
    [timerHttp invalidate];
    [timerHtsp invalidate];
    timerHttp = nil;
    timerHtsp = nil;
}

# pragma mark - xbmc results

- (NSArray*)foundServers
{
    NSMutableArray *serversFound = [[NSMutableArray alloc] init];
    
    for (NSNetService *serviceHtsp in foundServices) {
        if ([serviceHtsp.type isEqualToString:SERVICE_TYPE_HTSP]) {
            // go through the whole array again and try to match an HTTP server
            for (NSNetService *serviceHttp in foundServices) {
                if ([serviceHtsp.hostName isEqualToString:serviceHttp.hostName] &&
                    [serviceHtsp.name isEqualToString:serviceHttp.name] &&
                    [serviceHttp.type isEqualToString:SERVICE_TYPE_HTTP]) {
                    
                    TVHServerSettings *server = [[TVHServerSettings alloc] initWithSettings:@{TVHS_SERVER_NAME:serviceHttp.name, TVHS_IP_KEY:serviceHttp.hostName, TVHS_PORT_KEY:[NSString stringWithFormat:@"%lu",(long)serviceHttp.port], TVHS_HTSP_PORT_KEY:[NSString stringWithFormat:@"%lu",(long)serviceHtsp.port]}];
                    
                    [serversFound addObject:server];
                }
            }
        }
    }
    return [serversFound copy];
}


# pragma mark - resolveIPAddress Methods

- (void)resolveIPAddress:(NSNetService *)service {
    NSNetService *remoteService = service;
    remoteService.delegate = self;
    [remoteService resolveWithTimeout:0];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    
    [foundServices addObject:service];
    
    if ([self.delegate respondsToSelector:@selector(autoDiscoveryServersFound)]) {
        [self.delegate autoDiscoveryServersFound];
    }
}

- (void)stopDiscoveryHttp {
    [timerHttp invalidate];
    [netServiceBrowserHttp stop];
    
    if ([self.delegate respondsToSelector:@selector(stoppedAutoDiscovery)]) {
        [self.delegate stoppedAutoDiscovery];
    }
}


- (void)stopDiscoveryHtsp {
    [timerHtsp invalidate];
    [netServiceBrowserHtsp stop];
}

- (void)startDiscover{
    [services removeAllObjects];
    
    searching = NO;
    [netServiceBrowserHttp setDelegate:self];
    [netServiceBrowserHttp searchForServicesOfType:SERVICE_TYPE_HTTP inDomain:DOMAIN_NAME];
    timerHttp = [NSTimer scheduledTimerWithTimeInterval:DISCOVER_TIMEOUT target:self selector:@selector(stopDiscoveryHttp) userInfo:nil repeats:NO];
    
    [netServiceBrowserHtsp setDelegate:self];
    [netServiceBrowserHtsp searchForServicesOfType:SERVICE_TYPE_HTSP inDomain:DOMAIN_NAME];
    timerHtsp = [NSTimer scheduledTimerWithTimeInterval:DISCOVER_TIMEOUT target:self selector:@selector(stopDiscoveryHtsp) userInfo:nil repeats:NO];
}

# pragma mark - NSNetServiceBrowserDelegate Methods

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser{
    searching = YES;
    [self updateServers];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser{
    searching = NO;
    [self updateServers];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict{
    searching = NO;
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing {
    [services addObject:aNetService];
    if ( !moreComing ) {
        //[self stopDiscovery];
        [self updateServers];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing{
    [services removeObject:aNetService];
    if ( !moreComing ) {
        [self updateServers];
    }
}

- (void)handleError:(NSNumber *)error {
    NSLog(@"An error occurred. Error code = %d", [error intValue]);
}

- (void)updateServers {
    if ( !searching ) {
        for (NSNetService *service in services) {
            [self resolveIPAddress:service];
        }
    }
}

@end
