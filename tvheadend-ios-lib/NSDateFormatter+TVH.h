//
//  NSDate+TVHDateFormatters.h
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 29/01/2016.
//  Copyright © 2016 zipleen. All rights reserved.
//



@interface NSDateFormatter(TVHDateFormatters)
+ (NSDateFormatter *)dateFormatterMMddyy;
+ (NSDateFormatter *)dateFormatterDayExtended;
+ (NSDateFormatter *)timeFormatterHHmm;
+ (NSDateFormatter *)dateFormatterLongDate;
@end
