//
//  AFJSONUTF8HackResponseSerializer.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 21/08/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import "TVHJsonUTF8HackResponseSerializer.h"

@implementation TVHJsonUTF8HackResponseSerializer

+ (instancetype)serializer {
    return [[TVHJsonUTF8HackResponseSerializer alloc] init];
}

- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError * _Nullable __autoreleasing *)error NS_SWIFT_NOTHROW {

    NSMutableData *FileData = [NSMutableData dataWithLength:[data length]];
    for (int i = 0; i < [data length]; ++i)
    {
        char *a = &((char*)[data bytes])[i];
        if ( (int)*a > 0 && (int)*a < 0x20 ) {
            ((char*)[FileData mutableBytes])[i] = 0x20;
        } else if ( (int)*a > 0x7F ) {
            ((char*)[FileData mutableBytes])[i] = 0x20;
        } else {
            ((char*)[FileData mutableBytes])[i] = ((char*)[data bytes])[i];
        }
    }
    
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:FileData //1
                                                         options:kNilOptions
                                                           error:error];
    
    if( *error ) {
        NSLog(@"[JSON Error (TVHJsonUTF8HackResponseSerializer)] output - %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
#ifdef TESTING
        NSLog(@"[JSON Error (TVHJsonUTF8HackResponseSerializer)]: %@ ", (*error).description);
#endif
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Tvheadend returned malformed JSON - check your Tvheadend's Character Set for each mux and choose the correct one!", nil)] };
        *error = [[NSError alloc] initWithDomain:@"Not ready" code:NSURLErrorBadServerResponse userInfo:userInfo];
        return nil;
    }
    
    return json;
}

@end
