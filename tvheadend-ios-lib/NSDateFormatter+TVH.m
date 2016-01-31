//
//  NSDate+TVHDateFormatters.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 29/01/2016.
//  Copyright © 2016 zipleen. All rights reserved.
//

#import "NSDateFormatter+TVH.h"

@implementation NSDateFormatter(TVHDateFormatters)

+ (NSDateFormatter *)dateFormatterMMddyy
{
    static dispatch_once_t once;
    static NSDateFormatter *_dateFormatterMMddyy;
    dispatch_once(&once, ^ {
        _dateFormatterMMddyy = [[NSDateFormatter alloc] init];
        _dateFormatterMMddyy.dateFormat = @"MM/dd/yy";
    });
    return _dateFormatterMMddyy;
}

+ (NSDateFormatter *)dateFormatterDayExtended
{
    static dispatch_once_t once;
    static NSDateFormatter *_dateFormatterDayExtended;
    dispatch_once(&once, ^ {
        _dateFormatterDayExtended = [[NSDateFormatter alloc] init];
        _dateFormatterDayExtended.dateFormat = @"EEE";
    });
    return _dateFormatterDayExtended;
}

+ (NSDateFormatter *)timeFormatterHHmm
{
    static dispatch_once_t once;
    static NSDateFormatter *_timeFormatterHHmm;
    dispatch_once(&once, ^ {
        _timeFormatterHHmm = [[NSDateFormatter alloc] init];
        _timeFormatterHHmm.dateFormat = @"HH:mm";
    });
    return _timeFormatterHHmm;
}

+ (NSDateFormatter *)dateFormatterLongDate
{
    static dispatch_once_t once;
    static NSDateFormatter *_dateFormatterLongDate;
    dispatch_once(&once, ^ {
        _dateFormatterLongDate = [[NSDateFormatter alloc] init];
        _dateFormatterLongDate.dateFormat = @"E d MMM, HH:mm";
    });
    return _dateFormatterLongDate;
}


@end
