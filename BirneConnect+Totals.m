//
//  SummaryMaker.m
//  ASiST
//
//  Created by Oliver on 24.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "BirneConnect+Totals.h"
#import "YahooFinance.h"


@implementation BirneConnect (Totals)


/*
 select app_id, royalty_currency, count(*), sum(royalty_price) from report r, sale s where r.id = s.report_id and report_type_id = 0 and type_id=1 group by app_id, royalty_currency;
 */

// prepare a statement
static sqlite3_stmt *total_statement = nil;


- (void)getTotals
{
	// return dictionary
	NSMutableDictionary *byAppDict = [NSMutableDictionary dictionary];
	NSMutableDictionary *byReportDict = [NSMutableDictionary dictionary];
	
	
	// Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
	if (total_statement == nil) {
		// Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
		// This is a great way to optimize because frequently used queries can be compiled once, then with each
		// use new variable values can be bound to placeholders.
		const char *sql = "SELECT app_id, royalty_currency, sum(units), sum(units*royalty_price), report_id, min(report_type_id) FROM report r, sale s WHERE r.id = s.report_id and type_id=1 group by report_id, app_id, royalty_currency";
		if (sqlite3_prepare_v2(database, sql, -1, &total_statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
	}
	// For this query, we bind the primary key to the first (and only) placeholder in the statement.
	// Note that the parameters are numbered from 1, not from 0.
	while (sqlite3_step(total_statement) == SQLITE_ROW) 
	{
		NSUInteger app_id = sqlite3_column_int(total_statement, 0);
		NSString *currency_code = [NSString stringWithUTF8String:(char *)sqlite3_column_text(total_statement, 1)];
		NSUInteger units = sqlite3_column_int(total_statement, 2);
		double royalties = sqlite3_column_double(total_statement, 3);
		NSUInteger report_id = sqlite3_column_int(total_statement, 4);
		ReportType report_type_id = (ReportType)sqlite3_column_int(total_statement, 5);
		
		
		// sort the daily reports by app id
		if (report_type_id == ReportTypeDay)
		{
			// one dictionary per app, keys are currencies
			NSMutableDictionary *appDict = [byAppDict objectForKey:[NSNumber numberWithInt:app_id]];
			
			if (!appDict)
			{
				appDict = [NSMutableDictionary dictionary];
				[byAppDict setObject:appDict forKey:[NSNumber numberWithInt:app_id]];
			}
			
			NSMutableDictionary *sumsByCurrency = [appDict objectForKey:@"SumsByCurrency"];
			if (!sumsByCurrency)
			{
				sumsByCurrency = [NSMutableDictionary dictionary];
				[appDict setObject:sumsByCurrency forKey:@"SumsByCurrency"];
			}
			
			 // save individual currencies
			double royalties_plus_previous = royalties + [[sumsByCurrency objectForKey:currency_code] doubleValue];
			[sumsByCurrency setObject:[NSNumber numberWithDouble:royalties_plus_previous] forKey:currency_code];
			
			
			if (!royalties)
			{
				// count as free
				
				NSNumber *unitsEntry = [appDict objectForKey:@"UnitsFree"];
				
				if (!unitsEntry)
				{
					unitsEntry = [NSNumber numberWithInt:units];
				}
				else
				{
					unitsEntry = [NSNumber numberWithInt:(units + [unitsEntry intValue])];
				}
				
				[appDict setObject:unitsEntry forKey:@"UnitsFree"];
				
			}
			else
			{
				// count as paid
				
				NSNumber *unitsEntry = [appDict objectForKey:@"UnitsPaid"];
				
				if (!unitsEntry)
				{
					unitsEntry = [NSNumber numberWithInt:units];
				}
				else
				{
					unitsEntry = [NSNumber numberWithInt:(units + [unitsEntry intValue])];
				}
				
				[appDict setObject:unitsEntry forKey:@"UnitsPaid"];
				
			}
		}
		
		
		// sort all other sums into another dictionary
		NSMutableDictionary *reportDict = [byReportDict objectForKey:[NSNumber numberWithInt:report_id]];
		
		if (!reportDict)
		{
			reportDict = [NSMutableDictionary dictionary];
			[byReportDict setObject:reportDict forKey:[NSNumber numberWithInt:report_id]];
		}
		
		NSMutableDictionary *sumsByCurrency = [reportDict objectForKey:@"SumsByCurrency"];
		if (!sumsByCurrency)
		{
			sumsByCurrency = [NSMutableDictionary dictionary];
			[reportDict setObject:sumsByCurrency forKey:@"SumsByCurrency"];
		}
		
		// save individual currencies
		double royalties_plus_previous = royalties + [[sumsByCurrency objectForKey:currency_code] doubleValue];
		[sumsByCurrency setObject:[NSNumber numberWithDouble:royalties_plus_previous] forKey:currency_code];
			
		if (!royalties)
		{
			// count as free
			
			NSNumber *unitsEntry = [reportDict objectForKey:@"UnitsFree"];
			
			if (!unitsEntry)
			{
				unitsEntry = [NSNumber numberWithInt:units];
			}
			else
			{
				unitsEntry = [NSNumber numberWithInt:(units + [unitsEntry intValue])];
			}
			
			[reportDict setObject:unitsEntry forKey:@"UnitsFree"];
			
		}
		else
		{
			// count as paid
			
			NSNumber *unitsEntry = [reportDict objectForKey:@"UnitsPaid"];
			
			if (!unitsEntry)
			{
				unitsEntry = [NSNumber numberWithInt:units];
			}
			else
			{
				unitsEntry = [NSNumber numberWithInt:(units + [unitsEntry intValue])];
			}
			
			[reportDict setObject:unitsEntry forKey:@"UnitsPaid"];
			
		}
	}
	// Reset the statement for future reuse.
	sqlite3_reset(total_statement);
	
	NSDictionary *retDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:byAppDict, byReportDict, nil] forKeys:[NSArray arrayWithObjects:@"ByApp", @"ByReport", nil]];
	
	NSLog([retDict description]);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AppTotalsUpdated" object:nil userInfo:(id)retDict];
}

@end
