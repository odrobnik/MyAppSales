//
//  Query.m
//  ASiST
//
//  Created by Oliver Drobnik on 20.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Query.h"
#import "Report.h"
#import "YahooFinance.h"
#import "BirneConnect.h"
#import "App.h"


@implementation Query

- (id)initWithDatabase:(sqlite3 *)db
{
	if (self = [super init])
	{
		database = db;
		return self;
	}
	return nil;
}




- (NSDate *) dateFromString:(NSString *)rfc2822String
{
	if (!rfc2822String) return nil;
	
	if (!dateFormatterToRead)
	{
		dateFormatterToRead = [[NSDateFormatter alloc] init];
		[dateFormatterToRead setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"]; /* Unicode Locale Data Markup Language */
	}
	return [dateFormatterToRead dateFromString:rfc2822String]; /*e.g. @"Thu, 11 Sep 2008 12:34:12 +0200" */	
	
}

- (NSDictionary *) chartDataForReportType:(ReportType)report_type  ShowFree:(BOOL)show_free Axis:(NSString *)axis Itts:(BirneConnect *)itts
{
	// get a full sales report
	NSDictionary *report = [self salesReportForReportType:report_type];
	
	// we construct easy chartable data
	
	NSDictionary *tmpDict; //= [[NSMutableDictionary alloc] init];
	
	NSMutableArray *appsToInclude = [[NSMutableArray alloc] init];
	
	
	// column names
	
	NSMutableArray *colLabels = [[NSMutableArray alloc] init];
	NSArray *sortedApps = [itts appsSortedBySales];
	//NSArray *sortedAppKeys = [itts appKeysSortedBySales];
	NSEnumerator *enu = [sortedApps objectEnumerator];
	App *app;

	NSDictionary *royaltyTotals = [report objectForKey:@"Totals"];

	while (app = [enu nextObject]) 
	{
		// depending on show_free we add free apps or sold apps
		
		//NSDictionary *dataRoot = [data objectForKey:@"Data"];
		NSString *app_key = [NSString stringWithFormat:@"%d",app.apple_identifier]; 
		
		NSNumber *totalRoy = [royaltyTotals objectForKey:app_key];
	
		BOOL isFreeApp = (!totalRoy||([totalRoy doubleValue]==0));
		
		if (isFreeApp == show_free)
		{
			[colLabels addObject:app.title]; 
			//[appsToInclude setObject:app forKey:[NSNumber numberWithInt:app.apple_identifier]];
			[appsToInclude addObject:app];
		}
	}
	
	// row names (= days)
	
	NSDictionary *dataRoot = [report objectForKey:@"Data"];
	
	NSArray *days = [dataRoot allKeys];
	NSArray *rowLabels = [days sortedArrayUsingSelector:@selector(compare:)];

	// copy data into chart friendly array
	
	double maximum = 0;
	
	NSEnumerator *dateEnum = [rowLabels objectEnumerator];
	//NSDate *rowDate;
	NSString *rowDate;
	NSMutableArray *outputArray = [[NSMutableArray alloc] init];
	
	while (rowDate = [dateEnum nextObject]) 
	{
		NSDictionary *theRow = [dataRoot objectForKey:rowDate];
		NSMutableArray *output = [[NSMutableArray alloc] init];
		
		NSEnumerator *appEnu = [appsToInclude objectEnumerator];
		App *appKey;
				
		while (appKey = [appEnu nextObject]) 
		{
			NSString *app_key = [NSString stringWithFormat:@"%d", appKey.apple_identifier];
			//NSDictionary *theApp = [theRow objectForKey:[NSNumber numberWithInt:appKey.apple_identifier]];
			NSDictionary *theApp = [theRow objectForKey:app_key];
			NSNumber *data = [theApp objectForKey:axis];
			
			if (data)
			{
				[output addObject:data];
				if ([data doubleValue]>maximum)
				{
					maximum = [data doubleValue];
				}
			}
			else
			{
				[output addObject:[NSNumber numberWithInt:0]];
			}
		}
				
		[outputArray addObject:output];
		[output release];
	}
	
	// if there is only one row then let's duplicate it so that we see something on reports
	
	if ([rowLabels count]==1)
	{
		NSString * oneDay = (NSString *)[rowLabels objectAtIndex:0];
		NSString *nextDay = [[[self dateFromString:oneDay] addTimeInterval:60*60*24] description];
		NSMutableArray *oneRowData = [NSMutableArray arrayWithArray:[outputArray objectAtIndex:0]];
		NSMutableArray *mutableRowLabels = [NSMutableArray arrayWithArray:rowLabels];
		[mutableRowLabels addObject:nextDay];
		rowLabels = mutableRowLabels;
		[outputArray addObject:oneRowData];
	}
	
	NSArray *objects = [NSArray arrayWithObjects:colLabels, rowLabels, outputArray, [NSNumber numberWithDouble:maximum], [NSNumber numberWithInt:(int)report_type], axis, nil];
	NSArray *keys = [NSArray arrayWithObjects:@"Columns", @"Rows", @"Data", @"Maximum", @"ReportType", @"Axis", nil];
	
	tmpDict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];

	[colLabels release];
	[appsToInclude release];
	[outputArray release];
		
	return tmpDict;
}

- (NSDictionary *) stackAndTotalReport:(NSDictionary *)report
{
	// make it mutable
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:report];
		
	// for all rows: modify data so that each row is stacked on the previous and add total after the last
	NSMutableArray *data = [tmpDict objectForKey:@"Data"];
	NSEnumerator *en = [data objectEnumerator];
	
	double maximum = 0;
	
	NSMutableArray *row;
	
	while (row = [en nextObject]) 
	{
		double sumSoFar = 0;
		int idx = 0;
		
		NSNumber *num;
		
		
		for (idx=0;idx<[row count];idx++)
		{
			num = [row objectAtIndex:idx];
			[row replaceObjectAtIndex:idx withObject:[NSNumber numberWithDouble:[num doubleValue]+sumSoFar]];
			
			sumSoFar += [num doubleValue];
		}
		
		
		if (maximum<sumSoFar)
		{
			maximum = sumSoFar;
		}
	}
	
	
	[tmpDict setObject:[NSNumber numberWithDouble:maximum] forKey:@"Maximum"];
	
	NSDictionary *ret = [NSDictionary dictionaryWithDictionary:tmpDict];  //make it non-mutable
	return ret;
}



- (NSDictionary *) salesReportForReportType:(ReportType)report_type
{
	// see if there is a cached copy
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"cache_data_%d.plist", report_type]];

	NSDictionary *fromFile = [NSDictionary dictionaryWithContentsOfFile:path];
	
	if (fromFile)
	{
		return fromFile;
	}
	
	
	NSMutableDictionary *tmpDict = [[[NSMutableDictionary alloc] init] autorelease];
	NSMutableDictionary *dataDict = [[[NSMutableDictionary alloc] init] autorelease];
	[tmpDict setObject:dataDict forKey:@"Data"];
	NSMutableDictionary *royaltySumsPerApp = [[[NSMutableDictionary alloc] init] autorelease];
	[tmpDict setObject:royaltySumsPerApp forKey:@"Totals"];
	
	[tmpDict setObject:[NSNumber numberWithInt:(int)report_type] forKey:@"ReportType"];
	[tmpDict setObject:royaltySumsPerApp forKey:@"Totals"];
	
	
	sqlite3_stmt *statement = nil;
	const char *sql = "select report.from_date, app_id, sum(royalty_price*units), royalty_currency, sum(units) from sale, report where report_id = report.id and report.report_type_id = ? and sale.type_id = 1 group by report.from_date, app_id, royalty_currency";
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	
	// For this query, we bind the primary key to the first (and only) placeholder in the statement.
	// Note that the parameters are numbered from 1, not from 0.
	sqlite3_bind_int(statement, 1, (int)report_type);

	
	while (sqlite3_step(statement) == SQLITE_ROW) 
	{

		NSDate *lineDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
		
		NSInteger app_id = sqlite3_column_int(statement, 1);
		NSString *appKey = [NSString stringWithFormat:@"%d", app_id];

		double line_royalty = sqlite3_column_double(statement, 2);
		NSString *line_currency = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)];
		NSInteger line_units = sqlite3_column_int(statement, 4);
		
		NSMutableDictionary *dateDict;
		dateDict = [dataDict objectForKey:lineDate];
		
		if (!dateDict)
		{
			dateDict = [[NSMutableDictionary alloc] init];
			[dataDict setObject:dateDict forKey:lineDate];
			[dateDict release];
		}



		NSMutableDictionary *appDict;
		appDict = [dateDict objectForKey:appKey];
		
		
		if (!appDict)
		{
			appDict = [[NSMutableDictionary alloc] init];
			[dateDict setObject:appDict forKey:appKey];
			[appDict release];
		}

		double convertedRoyalties = [[YahooFinance sharedInstance] convertToEuro:line_royalty fromCurrency:line_currency]; 
		NSNumber *sumNum;
		sumNum = [appDict objectForKey:@"Sum"];
		
		if (!sumNum)
		{
			sumNum = [NSNumber numberWithDouble:convertedRoyalties];
			[appDict setObject:sumNum forKey:@"Sum"];
		}
		else
		{
			double sumSoFar = sumNum.doubleValue + convertedRoyalties;
			NSNumber *newSum = [NSNumber numberWithDouble:sumSoFar];
			[appDict setObject:newSum forKey:@"Sum"];
		}
		
		NSNumber *sumUnits;
		sumUnits = [appDict objectForKey:@"Units"];
		if (!sumUnits)
		{
			sumUnits = [NSNumber numberWithInt:line_units];
			[appDict setObject:sumUnits forKey:@"Units"];
		}
		else
		{
			int sumSoFar = sumUnits.intValue + line_units;
			NSNumber *newSum = [NSNumber numberWithInt:sumSoFar];
			[appDict setObject:newSum forKey:@"Units"];
		}
		
		// add the royalties per app, if one has total of 0 then it never had any sales aka "free app"
		NSNumber *prevSumOfApp = [royaltySumsPerApp objectForKey:appKey];
		if (!prevSumOfApp)
		{
			[royaltySumsPerApp setObject:[NSNumber numberWithDouble:convertedRoyalties] forKey:appKey];
		}
		else
		{
			double prevSum = [prevSumOfApp doubleValue];
			[royaltySumsPerApp setObject:[NSNumber numberWithDouble:convertedRoyalties+prevSum] forKey:appKey];
		}
		
	}  // while
		
	
	// save a cached copy in documents directory
	// but cache only if there is data in it
	if ([dataDict count]>0)
	{
		[tmpDict writeToFile:path atomically:YES];
	}
	// Finalize the statement, no reuse.
	sqlite3_finalize(statement);
	
//	[pool release];
	
	NSDictionary *retDict = [NSDictionary dictionaryWithDictionary:tmpDict];

	return retDict;
}



- (void)dealloc {
	[dateFormatterToRead release];
    [super dealloc];
}



@end
