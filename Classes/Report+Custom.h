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

@interface Report (Custom)

- (NSString *)sectionKey;

@end
