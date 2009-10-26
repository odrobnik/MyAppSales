//
//  NSArray+Reports.m
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NSArray+Reports.h"
#import "NSDate+Helpers.h"


@implementation NSArray (Reports)

- (Report *)reportBySearchingForDate:(NSDate *)reportDate type:(ReportType)reportType region:(ReportRegion)reportRegion
{
	for (Report *oneReport in self)
	{
		if ((oneReport.reportType == reportType)&&([oneReport.untilDate sameDateAs:reportDate])&&(oneReport.region == reportRegion))
		{
			return oneReport;
		}
	}
	
	// not found
	return nil;
}

@end
