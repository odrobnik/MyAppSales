//
//  NSArray+Reports.h
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Report_v1.h"


@interface NSArray (Reports)

- (Report_v1 *)reportBySearchingForDate:(NSDate *)reportDate type:(ReportType)reportType region:(ReportRegion)reportRegion;

@end
