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
			return @"Month (Financial)";
		case ReportTypeFree:
			return @"Month (Free)";
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

@end
