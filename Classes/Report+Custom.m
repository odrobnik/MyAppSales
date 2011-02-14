//
//  Report+Custom.m
//  ASiST
//
//  Created by Oliver on 06.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "Report+Custom.h"
#import "Product.h"
#import "ProductGroup.h"
#import "ReportTypes.h"

NSString *NSStringFromReportType(ReportType reportType)
{
	switch (reportType) {
		case ReportTypeDay:
			return @"Days";
		case ReportTypeWeek:
			return @"Weeks";
		case ReportTypeFinancial:
			return @"Months (Financial)";
		case ReportTypeFree:
			return @"Months (Free)";
		default:
			return @"Unknown";
	}
}

NSString *NSStringFromReportRegion(ReportRegion reportRegion)
{
	switch (reportRegion) {
		case ReportRegionUK:
			return @"United Kingdom";
		case ReportRegionUSA:
			return @"Americas";
		case ReportRegionEurope:
			return @"Euro-Zone";
		case ReportRegionJapan:
			return @"Japan";
		case ReportRegionCanada:
			return @"Canada";
		case ReportRegionAustralia:
			return @"Australia";
		case ReportRegionRestOfWorld:
			return @"Rest of World";
		default:
			return @"Invalid Region";
	}
}

NSString *NSStringFromReportRegionShort(ReportRegion reportRegion)
{
	switch (reportRegion) {
		case ReportRegionUK:
			return @"UK";
		case ReportRegionUSA:
			return @"US";
		case ReportRegionEurope:
			return @"EU";
		case ReportRegionJapan:
			return @"JP";
		case ReportRegionCanada:
			return @"CA";
		case ReportRegionAustralia:
			return @"AU";
		case ReportRegionRestOfWorld:
			return @"Rest";
		default:
			return @"Invalid Region";
	}
}

@implementation Report (Custom)

- (NSDate *)dateInMiddleOfReport
{
	NSTimeInterval start = [self.fromDate timeIntervalSince1970];
	NSTimeInterval finish = [self.untilDate timeIntervalSince1970];
	NSTimeInterval middle = (start + finish)/2.0;
	
	return [NSDate dateWithTimeIntervalSince1970:middle];
}

- (NSString *)yearMonth
{
	// sort it into the correct month
	NSDateComponents *dayComps = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSYearCalendarUnit 
																 fromDate:[self dateInMiddleOfReport]];
	
	NSString *yearMonthKey = [NSString stringWithFormat:@"%04d-%02d", [dayComps year], [dayComps month]];
	
	return yearMonthKey;
}

// group by product_group_id, product_type
- (NSString *)sectionKey
{
	return [NSString stringWithFormat:@"%@\t%@\t%@", self.productGrouping.title, self.reportType, self.productGrouping.identifier];
	
}


- (NSString *)shortTitleForBackButton
{
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];

	switch ([self.reportType intValue]) 
	{
		case ReportTypeDay:
		{
			[df setDateStyle:NSDateFormatterShortStyle];
			[df setTimeStyle:NSDateFormatterNoStyle];
			return [df stringFromDate:self.fromDate];
		}
		case ReportTypeWeek:
		{
			[df setDateFormat:@"'Week' w"];
			return [df stringFromDate:self.fromDate];
		}
		case ReportTypeFinancial:
		case ReportTypeFree:
		{
			NSDate *date = [self dateInMiddleOfReport];
			[df setDateFormat:@"MMM"];
			return [df stringFromDate:date];
		}
		default:
			return @"Unknown";
	}
}

- (NSString *)titleForNavBar
{
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	
	switch ([self.reportType intValue]) 
	{
		case ReportTypeDay:
		{
			[df setDateStyle:NSDateFormatterMediumStyle];
			[df setTimeStyle:NSDateFormatterNoStyle];
			return [df stringFromDate:self.fromDate];
		}
		case ReportTypeWeek:
		{
			[df setDateFormat:@"'Week' w, yyyy"];
			return [df stringFromDate:self.fromDate];
		}
		case ReportTypeFinancial:
		case ReportTypeFree:
		{
			NSDate *date = [self dateInMiddleOfReport];
			[df setDateFormat:@"MMM yy"];
			return [NSString stringWithFormat:@"%@ (%@)", NSStringFromReportRegionShort([self.region intValue]),
					[df stringFromDate:date]];
		}
		default:
			return @"Unknown";
	}
}
@end
