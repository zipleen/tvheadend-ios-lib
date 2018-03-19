//
//  TVHPlayChromeCast.m
//  tvheadend-ios-lib
//
//  Created by zipleen on 07/09/14.
//  Copyright (c) 2014 zipleen. All rights reserved.
//

#ifdef ENABLE_CHROMECAST

#import "TVHPlayChromeCast.h"

static NSString * kReceiverAppID;

@interface TVHPlayChromeCast ()

@property GCKMediaControlChannel *mediaControlChannel;
@property GCKApplicationMetadata *applicationMetadata;
@property GCKDevice *selectedDevice;
@property(nonatomic, strong) GCKDeviceScanner *deviceScanner;
@property(nonatomic, strong) GCKDeviceManager *deviceManager;
@property(nonatomic, readonly) GCKMediaInformation *mediaInformation;

@property(nonatomic, strong) id<TVHPlayStreamDelegate> streamObject;
@end

@implementation TVHPlayChromeCast

+ (TVHPlayChromeCast*)sharedInstance {
    static TVHPlayChromeCast *__sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[TVHPlayChromeCast alloc] init];
    });
    return __sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        kReceiverAppID=kGCKMediaDefaultReceiverApplicationID;
        
        self.deviceScanner = [[GCKDeviceScanner alloc] initWithFilterCriteria:[GCKFilterCriteria criteriaForAvailableApplicationWithID:kReceiverAppID]];
        
        [self.deviceScanner addListener:self];
        [self.deviceScanner startScan];

    }
    return self;
}

# pragma mark - xbmc play action

- (BOOL)playStream:(NSString*)serverName forObject:(id<TVHPlayStreamDelegate>)streamObject withAnalytics:(id<TVHModelAnalyticsProtocol>)analytics {
    
    GCKDevice *device = [self.foundServices objectForKey:serverName];
    if ( [device isEqual:@NO] ) {
        [self deviceDisconnect];
        return true;
    }
    
    if ( device ) {
        NSLog(@"Cast Video");
        
        if (self.deviceManager && self.deviceManager.isConnected) {
            [self deviceDisconnect];
        }
        [self connectToDevice:device];
        
        self.streamObject = streamObject;
        
        return true;
    }
    
    return false;
}

- (void)connectToDevice:(GCKDevice*)device {
    self.selectedDevice = device;
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.deviceManager =
    [[GCKDeviceManager alloc] initWithDevice:device
                           clientPackageName:[info objectForKey:@"CFBundleIdentifier"]];
    self.deviceManager.delegate = self;
    [self.deviceManager connect];
    
}

# pragma mark - xbmc results

- (NSDictionary*)foundServices
{
    [self updateStatsFromDevice];
    
    NSMutableDictionary *devices = [[NSMutableDictionary alloc] init];
    for (GCKDevice *device in self.deviceScanner.devices) {
        if (device.friendlyName) {
            [devices setObject:device forKey:device.friendlyName];
        }
    }
    
    if (self.selectedDevice) {
        [devices setObject:@NO forKey:[@"Disconnect " stringByAppendingString:self.selectedDevice.friendlyName]];
    }
    return [devices copy];
}

- (NSArray*)availableServers {
    return [[self foundServices] allKeys];
}

// @todo this is broken, we need to implement completionBlock!
- (NSString*)validUrlForObject:(id<TVHPlayStreamDelegate>)streamObject  {
    return [streamObject streamUrlWithInternalPlayer:NO];
}


- (void)deviceDisconnect {
    NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
    // New way of doing things: We're not going to stop the applicaton. We're just going
    // to leave it.
    [self.deviceManager leaveApplication];
    // If you want to force application to stop, uncomment below
    //[self.deviceManager stopApplicationWithSessionID:self.applicationMetadata.sessionID];
    [self.deviceManager disconnect];
    
    [self deviceDisconnected];
}

- (void)deviceDisconnected {
    self.mediaControlChannel = nil;
    self.deviceManager = nil;
    self.selectedDevice = nil;
}

- (void)updateButtonStates
{
    
}

- (BOOL)isConnected {
    return self.deviceManager.isConnected;
}

- (void)updateStatsFromDevice {
    
    if (self.mediaControlChannel && self.isConnected) {
        _mediaInformation = self.mediaControlChannel.mediaStatus.mediaInformation;
    }
}

#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device {
    NSLog(@"device found!! %@", device.friendlyName);
    [self updateButtonStates];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
    [self updateButtonStates];
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
    NSLog(@"connected!!");
    
    [self updateButtonStates];
    [self.deviceManager launchApplication:kReceiverAppID];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication {
    
    NSLog(@"application has launched");
    self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
    self.mediaControlChannel.delegate = self;
    [self.deviceManager addChannel:self.mediaControlChannel];
    [self.mediaControlChannel requestStatus];
    
    // start the stream after launching app
    [self castVideo];
}

- (void)castVideo
{
    //Define Media metadata
    GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
    
    [metadata setString:[self.streamObject name]
                 forKey:kGCKMetadataKeyTitle];
    
    [metadata setString:[self.streamObject description]
                 forKey:kGCKMetadataKeySubtitle];
    
    if (![self.streamObject imageUrl]) {
        [metadata addImage:[[GCKImage alloc]
                            initWithURL:[[NSURL alloc] initWithString:[self.streamObject imageUrl]]
                            width:300
                            height:300]];
    }
    
    //define Media information
    GCKMediaInformation *mediaInformation =
    [[GCKMediaInformation alloc] initWithContentID:
     [self validUrlForObject:self.streamObject]
                                        streamType:GCKMediaStreamTypeLive
                                       contentType:@"video/mp4"
                                          metadata:metadata
                                    streamDuration:0
                                        customData:nil];
    
    //cast video
    [_mediaControlChannel loadMedia:mediaInformation autoplay:TRUE playPosition:0];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToConnectToApplicationWithError:(NSError *)error {
    [self showError:error];
    
    [self deviceDisconnected];
    [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didFailToConnectWithError:(GCKError *)error {
    [self showError:error];
    
    [self deviceDisconnected];
    [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(GCKError *)error {
    NSLog(@"Received notification that device disconnected");
    
    if (error != nil) {
        [self showError:error];
    }
    
    //[self deviceDisconnected];
    [self updateButtonStates];
    
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
didReceiveStatusForApplication:(GCKApplicationMetadata *)applicationMetadata {
    self.applicationMetadata = applicationMetadata;
}

#pragma mark - misc
- (void)showError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                    message:NSLocalizedString(error.description, nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

@end

#endif
