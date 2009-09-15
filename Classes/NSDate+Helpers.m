//
//  NSDate+Helpers.m
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NSDate+Helpers.h"


@implementation NSDate (Helpers)



// If two NSDates represent times on the same day (relative to the
// receiver's time zone), they will have the same day number.

- (long) dayNumber
{
    return (long) floor(([self timeIntervalSinceReferenceDate] + [[NSTimeZone localTimeZone] secondsFromGMTForDate:self]) / (double)(60*60*24));
}




// Compare two calendar dates, ignoring intraday time.  Return YES if they
// are both the same date.

- (BOOL) sameDateAs:(NSDate *) other
{
    BOOL retValue = YES;
	
    if (self != other)
    {
        retValue = ([self dayNumber] == [other dayNumber]);
    }
    return retValue;
}

- (NSDate *) dateAtBeginningOfDay
{
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *comps = [gregorian components:NSDayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit fromDate:self];
	
	return [gregorian dateFromComponents:comps];
}

@end
