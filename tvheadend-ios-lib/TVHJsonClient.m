//
//  TVHJsonClient.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/22/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHServerSettings.h"
#import "TVHJsonClient.h"
#import "TVHJsonUTF8AutoCharsetResponseSerializer.h"
#import "TVHJsonUTF8HackResponseSerializer.h"

#ifdef ENABLE_SSH
#import "SSHWrapper.h"
#endif

#ifndef DEVICE_IS_TVOS
/**
  we do not want to keep saying we're doing network activity in relation to the comet/poll, so we ignore it. 
 */
@implementation TVHNetworkActivityIndicatorManager

- (void)networkRequestDidStart:(NSNotification *)notification {
    NSURL *url = [AFNetworkRequestFromNotification(notification) URL];
    if (url) {
        if ( ! [url.path isEqualToString:@"/comet/poll"] ) {
            [self incrementActivityCount];
        }
    }
}

- (void)networkRequestDidFinish:(NSNotification *)notification {
    NSURL *url = [AFNetworkRequestFromNotification(notification) URL];
    if (url) {
        if ( ! [url.path isEqualToString:@"/comet/poll"] ) {
            [self decrementActivityCount];
        }
    }
}

@end
#endif

@implementation TVHJsonClient {
#ifdef ENABLE_SSH
    SSHWrapper *sshPortForwardWrapper;
#endif
}

#pragma mark - Authentication

- (void)setUsername:(NSString *)username password:(NSString *)password in:(AFHTTPRequestSerializer*)requestSerializer {
    
    [self setTaskDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
        NSString *authenicationMethod = challenge.protectionSpace.authenticationMethod;
        if (challenge.previousFailureCount > 0) {
            return NSURLSessionAuthChallengePerformDefaultHandling;
        }
        
        if ([authenicationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
            *credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceForSession];
            return NSURLSessionAuthChallengeUseCredential;
        }
        if ([authenicationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
            *credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceForSession];
            return NSURLSessionAuthChallengeUseCredential;
        }
        return NSURLSessionAuthChallengeCancelAuthenticationChallenge;
    }];
}

#pragma mark - Initialization

- (id)init
{
    [NSException raise:@"Invalid Init" format:@"JsonClient needs ServerSettings to work"];
    return nil;
}

- (id)initWithSettings:(TVHServerSettings *)settings {
    NSParameterAssert(settings);

#ifdef ENABLE_SSH
    // setup port forward
    if ( [settings.sshPortForwardHost length] > 0 ) {
        [self setupPortForwardToHost:settings.sshPortForwardHost
                           onSSHPort:[settings.sshPortForwardPort intValue]
                        withUsername:settings.sshPortForwardUsername
                        withPassword:settings.sshPortForwardPassword
                         onLocalPort:[TVHS_SSH_PF_LOCAL_PORT intValue]
                              toHost:settings.sshHostTo
                        onRemotePort:[settings.sshPortTo intValue]
         ];
        _readyToUse = NO;
    } else {
        _readyToUse = YES;
    }
#else
    _readyToUse = YES;
#endif
    
    self = [super initWithBaseURL:settings.baseURL];
    if (!self) {
        return nil;
    }
    
    [self setupRequestSerializer:settings];
    [self setupResponseSerializer:settings];
    
#ifndef DEVICE_IS_TVOS
    [[TVHNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
#endif
    
    if ([[AFNetworkReachabilityManager sharedManager] isReachable]) {
        _readyToUse = YES;
    }
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if ( status == AFNetworkReachabilityStatusNotReachable ) {
            @synchronized(self) {
                _readyToUse = NO;
            }
        } else {
            @synchronized(self) {
                _readyToUse = YES;
            }
        }
    }];
    
    return self;
}

- (void)setupRequestSerializer:(TVHServerSettings *)settings {
    // requests are done as json calls + authentication
    AFHTTPRequestSerializer *jsonRequestSerializer = [AFHTTPRequestSerializer serializer];
    if( [settings.username length] > 0 ) {
        [self setUsername:settings.username password:settings.password in:jsonRequestSerializer];
    }
    self.requestSerializer = jsonRequestSerializer;
}

- (void)setupResponseSerializer:(TVHServerSettings *)settings {
    // 1.
    AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:0];
    NSSet *acceptableContentTypes = jsonSerializer.acceptableContentTypes;
    acceptableContentTypes = [acceptableContentTypes setByAddingObject:@"text/x-json"];
    jsonSerializer.acceptableContentTypes = acceptableContentTypes;
    
    // 2. the auto charset conversion before decoding the json
    TVHJsonUTF8AutoCharsetResponseSerializer *jsonAutoCharsetSerializer = [TVHJsonUTF8AutoCharsetResponseSerializer serializer];
    
    // 3. my very bad json crap trying to hack what the first one could not (right now I think this never gets triggered)
    TVHJsonUTF8HackResponseSerializer *jsonHackSerializer = [TVHJsonUTF8HackResponseSerializer serializer];
    
    self.responseSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[jsonSerializer, jsonAutoCharsetSerializer, jsonHackSerializer]];
}

- (void)dealloc {
    [[self operationQueue] cancelAllOperations];
    [self stopPortForward];
}

#pragma mark AFHTTPClient methods

- (NSURLSessionDataTask*)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
        failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    if ( ! [self readyToUse] ) {
        [self dispatchNotReadyError:failure];
        return nil;
    }
    
    return [self GET:path parameters:parameters progress:nil success:success failure:failure];
}


- (NSURLSessionDataTask*)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    if ( ! [self readyToUse] ) {
        [self dispatchNotReadyError:failure];
        return nil;
    }
    return [super POST:path parameters:parameters progress:nil success:success failure:failure];
}

- (void)dispatchNotReadyError:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    NSLog(@"TVHJsonClient: not ready or not reachable yet, aborting... ");
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Server not reachable or not yet ready to connect.", nil)] };
    NSError *error = [[NSError alloc] initWithDomain:@"Not ready" code:NSURLErrorBadServerResponse userInfo:userInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        failure(nil, error);
    });
}

#pragma mark SSH

- (void)setupPortForwardToHost:(NSString*)hostAddress
                     onSSHPort:(unsigned int)sshHostPort
                  withUsername:(NSString*)username
                  withPassword:(NSString*)password
                   onLocalPort:(unsigned int)localPort
                        toHost:(NSString*)remoteIp
                  onRemotePort:(unsigned int)remotePort  {
#ifdef ENABLE_SSH
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSError *error;
        sshPortForwardWrapper = [[SSHWrapper alloc] init];
        [sshPortForwardWrapper connectToHost:hostAddress port:sshHostPort user:username password:password error:&error];
        if ( !error ) {
            _readyToUse = YES;
            [sshPortForwardWrapper setPortForwardFromPort:localPort toHost:remoteIp onPort:remotePort];
            _readyToUse = NO;
        } else {
            NSLog(@"erro ssh pf: %@", error.localizedDescription);
        }
    });
#endif
}

- (void)stopPortForward {
#ifdef ENABLE_SSH
    if ( ! sshPortForwardWrapper ) {
        return ;
    }
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [sshPortForwardWrapper closeConnection];
        sshPortForwardWrapper = nil;
    });
#endif
}
@end
