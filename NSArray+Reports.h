//
//  NSArray+Reports.h
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Report.h"


@interface NSArray (Reports)

- (Report *)reportBySearchingForDate:(NSDate *)reportDate type:(ReportType)reportType region:(ReportRegion)reportRegion;

@end
