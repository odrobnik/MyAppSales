//
//  NSString+Review.m
//  ASiST
//
//  Created by Oliver on 02.10.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "NSString+Review.h"


@implementation NSString (Review)

- (NSDate *)dateFromReviewDataString
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	// May 4, 2009
	[dateFormatter setDateFormat:@"MMM dd, yyyy"]; /* Unicode Locale Data Markup Language */
	//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
	NSDate *reviewDate = [dateFormatter dateFromString:self]; 
	[dateFormatter release];
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"dd-MMM-yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"dd-MM-yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"dd.MMM.yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"dd.MM.yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr_FR"] autorelease];
		[dateFormatter setLocale:frLocale];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"dd MMM yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"es_ES"] autorelease];
		[dateFormatter setLocale:frLocale];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"dd-MMM-yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"it_IT"] autorelease];
		[dateFormatter setLocale:frLocale];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"dd-MMM-yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
		[dateFormatter setLocale:frLocale];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"dd-MMM-yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	
	if (!reviewDate)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
		[dateFormatter setLocale:frLocale];
		// 09-Oct-2008
		[dateFormatter setDateFormat:@"MMM dd, yyyy"]; /* Unicode Locale Data Markup Language */
		//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
		reviewDate = [dateFormatter dateFromString:self]; 
		[dateFormatter release];
	}
	if (!reviewDate)
	{
		NSLog(@"Cannot parse date: '%@'", self);
	}
	return reviewDate;
}

@end
