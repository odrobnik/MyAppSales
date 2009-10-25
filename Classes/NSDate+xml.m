//
//  NSDate+xml.m
//  TestTest
//
//  Created by Oliver on 17.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NSDate+xml.h"


@implementation NSDate (xml)


- (NSString *) ISO8601string
{
	NSDateFormatter *sISO8601 = [[[NSDateFormatter alloc] init] autorelease];
	[sISO8601 setTimeStyle:NSDateFormatterFullStyle];
	
	[sISO8601 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
	[sISO8601 setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	
	return [[sISO8601 stringFromDate:self] stringByAppendingString:@"Z"];
}


@end
