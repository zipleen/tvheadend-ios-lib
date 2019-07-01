//
//  AFJSONUTF8FixResponseSerializer.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 21/08/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import "TVHJsonUTF8AutoCharsetResponseSerializer.h"


@implementation TVHJsonUTF8AutoCharsetResponseSerializer

+ (instancetype)serializer {
    return [[TVHJsonUTF8AutoCharsetResponseSerializer alloc] init];
}

/**
 this method will try to convert to a string the various different encodings and then strip the control characters.
 thanks to Maury Markowitz @maurymarkowitz for the testing and fixes for this !
 https://github.com/maurymarkowitz/tvheadend-ios-lib/commit/31644825e4e010046dcc34d377748ca3441fe1c5
 */
- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError * _Nullable __autoreleasing *)error NS_SWIFT_NOTHROW {
    NSString *convertedString;
    
    // try various encodings to see if any of them produce a working string
    // note that the ordering here is "best guess", there's no real promise it will
    // do the right thing in a wide variety of cases, but it seems that it will produce
    // some sort of readable text in most cases.
    
    NSUInteger encodings[3] = {
        NSUTF8StringEncoding,
        NSISOLatin1StringEncoding,
        NSASCIIStringEncoding
    };
    
    for (int i = 0; i < 3; i++) {
        convertedString = [[NSString alloc] initWithData:data encoding:encodings[i]];
        if ( convertedString != nil ) {
            break;
        }
    }
    
    if ( !convertedString ) {
#ifdef TESTING
        NSLog(@"[JSON Error (TVHJsonUTF8AutoCharsetResponseSerializer)]: Converted String did not work. aborting ");
#endif
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Tvheadend returned malformed JSON - check your Tvheadend's Character Set for each mux and choose the correct one!", nil)] };
        *error = [[NSError alloc] initWithDomain:@"Not ready" code:NSURLErrorBadServerResponse userInfo:userInfo];
        return nil;
    }
    
    // now the next problem is that we are also receiving control characters. these are properly
    // escaped, but the JSON parser won't accept them. So here we'll use an NSScanner to remove them
    NSCharacterSet *controls = [NSCharacterSet controlCharacterSet];
    NSString *stripped = [[convertedString componentsSeparatedByCharactersInSet:controls] componentsJoinedByString:@""];
    
    // now we try converting the string to data - if we cannot convert back, fallback to the previous method
    NSData *convertedData = [stripped dataUsingEncoding:NSUTF8StringEncoding];
    if ( !convertedData ) {
#ifdef TESTING
        NSLog(@"[JSON Error (TVHJsonUTF8AutoCharsetResponseSerializer)]: Converted character set did not work. aborting.  ");
#endif
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:[NSString stringWithFormat:NSLocalizedString(@"Tvheadend returned malformed JSON - check your Tvheadend's Character Set for each mux and choose the correct one!", nil)] };
        *error = [[NSError alloc] initWithDomain:@"Not ready" code:NSURLErrorBadServerResponse userInfo:userInfo];
        return nil;
    }
    
    // and finally, try parsing the data as JSON
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:convertedData
                                                         options:kNilOptions
                                                           error:error];
    
    return json;
}

@end
