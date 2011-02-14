//
//  Report+Custom.h
//  ASiST
//
//  Created by Oliver on 06.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Report.h"
#import "ReportTypes.h"

NSString *NSStringFromReportType(ReportType reportType);
NSString *NSStringFromReportRegion(ReportRegion reportRegion);
NSString *NSStringFromReportRegionShort(ReportRegion reportRegion);

@interface Report (Custom)

- (NSString *)sectionKey;

- (NSString *)shortTitleForBackButton;
- (NSString *)titleForNavBar;

@end
