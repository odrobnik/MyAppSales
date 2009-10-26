//
//  Query.h
//  ASiST
//
//  Created by Oliver Drobnik on 20.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "Report.h"

@interface Query : NSObject 
{
	
    sqlite3 *database; // Opaque reference to the underlying database.
	
	
	// helper
	NSDateFormatter *dateFormatterToRead;
}


- (NSDate *) dateFromString:(NSString *)rfc2822String;

- (id)initWithDatabase:(sqlite3 *)db;
- (NSDictionary *) salesReportForReportType:(ReportType)report_type;
- (NSDictionary *) chartDataForReportType:(ReportType)report_type ShowFree:(BOOL)show_free Axis:(NSString *)axis;
- (NSDictionary *) stackAndTotalReport:(NSDictionary *)report;

- (NSDate *) dateFromString:(NSString *)rfc2822String;


@end
