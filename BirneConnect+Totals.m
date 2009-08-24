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
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	// Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
	if (total_statement == nil) {
		// Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
		// This is a great way to optimize because frequently used queries can be compiled once, then with each
		// use new variable values can be bound to placeholders.
		const char *sql = "SELECT app_id, royalty_currency, sum(units), sum(royalty_price) FROM report r, sale s WHERE r.id = s.report_id and report_type_id = 0 and type_id=1 group by app_id, royalty_currency";
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
		
		NSMutableDictionary *appDict = [tmpDict objectForKey:[NSNumber numberWithInt:app_id]];
		
		if (!appDict)
		{
			appDict = [NSMutableDictionary dictionary];
			[tmpDict setObject:appDict forKey:[NSNumber numberWithInt:app_id]];
		}
	
		NSMutableDictionary *currencyDict = [appDict objectForKey:currency_code];
		
		if (!currencyDict)
		{
			currencyDict = [NSMutableDictionary dictionary];
			[appDict setObject:currencyDict forKey:currency_code];
		}
	
		[appDict setObject:[NSNumber numberWithDouble:royalties] forKey:currency_code];
		
		
		NSNumber *unitsEntry = [appDict objectForKey:@"Units"];
		
		if (!unitsEntry)
		{
			unitsEntry = [NSNumber numberWithInt:units];
		}
		else
		{
			unitsEntry = [NSNumber numberWithInt:(units + [unitsEntry intValue])];
		}
		
		[appDict setObject:unitsEntry forKey:@"Units"];
		
		NSNumber *royalitiesEntry = [appDict objectForKey:@"Royalties"];
		
		double royalties_converted = [[YahooFinance sharedInstance] convertToCurrency:@"EUR" amount:royalties fromCurrency:currency_code];
		
		if (!royalitiesEntry)
		{
			royalitiesEntry = [NSNumber numberWithDouble:royalties_converted];
		}
		else
		{
			royalitiesEntry = [NSNumber numberWithDouble:(royalties_converted + [royalitiesEntry doubleValue])];
		}
		
		[appDict setObject:royalitiesEntry forKey:@"Royalties"];
	}
	// Reset the statement for future reuse.
	sqlite3_reset(total_statement);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AppTotalsUpdated" object:nil userInfo:(id)tmpDict];
}

@end
