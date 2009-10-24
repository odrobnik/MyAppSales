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

+ (NSDate *) dateFromRFC2822String:(NSString *)rfc2822String
{
	NSDateFormatter *dateFormatterToRead = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatterToRead setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"]; /* Unicode Locale Data Markup Language */
	
	return [dateFormatterToRead dateFromString:rfc2822String]; /*e.g. @"Thu, 11 Sep 2008 12:34:12 +0200" */	
}

+ (NSDate *) dateFromMonth:(int)month Year:(int)year
{
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setDay:1];
	[comps setMonth:month];
	[comps setYear:year];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	NSDate *date = [gregorian dateFromComponents:comps];
	[comps release];
	[gregorian release];
	
	return date;
}


@end
