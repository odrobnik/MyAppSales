//
//  Product.m
//  ASiST
//
//  Created by Oliver on 25.11.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "Product.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
#import "ReviewDownloaderOperation.h"
#import "Review.h"
#import "Database.h"
#import "Country.h"
#import "SynchingManager.h"

#import "App.h"
#import "Report.h"
#import "NSString+Helpers.h"


// Static variables for compiled SQL queries. This implementation choice is to be able to share a one time
// compilation of each query across all instances of the class. Each time a query is used, variables may be bound
// to it, it will be "stepped", and then reset for the next usage. When the application begins to terminate,
// a class method will be invoked to "finalize" (delete) the compiled queries - this must happen before the database
// can be closed.
static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *delete_statement = nil;
static sqlite3_stmt *update_statement = nil;

//static sqlite3_stmt *delete_points_statement = nil;

static sqlite3_stmt *total_statement = nil;
//static sqlite3_stmt *dehydrate_statement = nil;

// Date formatter for XML files
static NSDateFormatter *dateFormatterToRead = nil;


@interface Product ()

- (void) getTotalsFromCacheIfPossible:(BOOL)canUseCache;
@end



@implementation Product
@synthesize isNew, averageRoyaltiesPerDay, apple_identifier, totalRoyalties, totalUnits;

- (id)init
{
	// default images
	if (self = [super init])
	{		
		// subscribe to total update notifications
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTotalsUpdated:) name:@"AppTotalsUpdated" object:nil];
		// subscribe to cache emptying
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyCache:) name:@"EmptyCache" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRatesChanged:) name:@"ExchangeRatesChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:@"UIApplicationWillTerminateNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newReportAdded:) name:@"NewReportAdded" object:nil];
	}
	
	return self;
}

- (void)dealloc 
{
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[sumsByCurrency release];
	[title release];
	[vendor_identifier release];
    [company_name release];
	
    [super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Product: %@ %.2f", title, averageRoyaltiesPerDay];
}

- (NSDate *) dateFromString:(NSString *)rfc2822String
{
	if (!dateFormatterToRead)
	{
		dateFormatterToRead = [[NSDateFormatter alloc] init];
		[dateFormatterToRead setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"]; /* Unicode Locale Data Markup Language */
	}
	return [dateFormatterToRead dateFromString:rfc2822String]; /*e.g. @"Thu, 11 Sep 2008 12:34:12 +0200" */	
}


// Creates the object with primary key and title is brought into memory.
- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    if (self = [self init]) 
	{
        apple_identifier = pk;
        database = db;
        // Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
        if (init_statement == nil) {
            // Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
            // This is a great way to optimize because frequently used queries can be compiled once, then with each
            // use new variable values can be bound to placeholders.
            const char *sql = "SELECT title, vendor_identifier, company_name FROM app WHERE id=?";
            if (sqlite3_prepare_v2(database, sql, -1, &init_statement, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }
        // For this query, we bind the primary key to the first (and only) placeholder in the statement.
        // Note that the parameters are numbered from 1, not from 0.
        sqlite3_bind_int(init_statement, 1, apple_identifier);
        if (sqlite3_step(init_statement) == SQLITE_ROW) {
            self.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 0)];
            self.vendor_identifier = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 1)];
            self.company_name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 2)];
        } else {
            self.title = @"No title";
        }
        // Reset the statement for future reuse.
        sqlite3_reset(init_statement);
        dirty = NO;
		
		
    }
	
	
    return self;
}


// used to create new apps, primary key must not be in the DB already
- (id) initWithTitle:(NSString *)a_title vendor_identifier:(NSString *)a_vendor_identifier apple_identifier:(NSUInteger)a_apple_identifier company_name:(NSString *)a_company_name database:(sqlite3 *)db
{
	if (self = [self init])
	{
		database = db;
		self.title = a_title;  // property copies it anyway, app is "dirty" after setting
		self.vendor_identifier = a_vendor_identifier;
		apple_identifier = a_apple_identifier;
		self.company_name = a_company_name;
		
		isNew = YES;
		
		[self insertIntoDatabase:database];
		
		return self;
	}
	else
	{
		return nil;
	}
	
}

- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO Product(id, title, vendor_identifier, company_name) VALUES(?, ?, ?, ?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_int(insert_statement, 1, apple_identifier);
    sqlite3_bind_text(insert_statement, 2, [title UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 3, [vendor_identifier UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 4, [company_name UTF8String], -1, SQLITE_TRANSIENT);
	
    int success = sqlite3_step(insert_statement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insert_statement);
	
	NSAssert2((success == SQLITE_OK) || (success >= SQLITE_ROW), @"Error: sqlite3_step failed with error %d (%s).", success, sqlite3_errmsg(database));
}

- (void)deleteFromDatabase {
    // Compile the delete statement if needed.
    if (delete_statement == nil) {
        const char *sql = "DELETE FROM Product WHERE id=?";
        if (sqlite3_prepare_v2(database, sql, -1, &delete_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_int(delete_statement, 1, apple_identifier);
    // Execute the query.
    int success = sqlite3_step(delete_statement);
    // Reset the statement for future use.
    sqlite3_reset(delete_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
    }
}

- (void)updateInDatabase {
    // Compile the delete statement if needed.
    if (update_statement == nil) {
        const char *sql = "UPDATE Product set title = ? WHERE id=?";
        if (sqlite3_prepare_v2(database, sql, -1, &update_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_text(update_statement, 1, [title UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(update_statement, 2, apple_identifier);
    // Execute the query.
    int success = sqlite3_step(update_statement);
    // Reset the statement for future use.
    sqlite3_reset(update_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to update in database with message '%s'.", sqlite3_errmsg(database));
    }
}

#pragma mark Properties
// Accessors implemented below. All the "get" accessors simply return the value directly, with no additional
// logic or steps for synchronization. The "set" accessors attempt to verify that the new value is definitely
// different from the old value, to minimize the amount of work done. Any "set" which actually results in changing
// data will mark the object as "dirty" - i.e., possessing data that has not been written to the database.
// All the "set" accessors copy data, rather than retain it. This is common for value objects - strings, numbers, 
// dates, data buffers, etc. This ensures that subsequent changes to either the original or the copy don't violate 
// the encapsulation of the owning object.

- (NSUInteger)apple_identifier {
    return apple_identifier;
}

- (NSString *)title {
    return title;
}

- (void)setTitle:(NSString *)aString {
    if ((!title && !aString) || (title && aString && [title isEqualToString:aString])) return;
    dirty = YES;
    [title release];
    title = [aString copy];
}

- (NSString *)company_name {
    return company_name;
}

- (void)setCompany_name:(NSString *)aString {
    if ((!company_name && !aString) || (company_name && aString && [company_name isEqualToString:aString])) return;
    dirty = YES;
    [company_name release];
    company_name = [aString copy];
}

- (NSString *)vendor_identifier {
    return vendor_identifier;
}

- (void)setVendor_identifier:(NSString *)aString {
    if ((!vendor_identifier && !aString) || (vendor_identifier && aString && [vendor_identifier isEqualToString:aString])) return;
    dirty = YES;
    [vendor_identifier release];
    vendor_identifier = [aString copy];
}

- (NSNumber *) identifierAsNumber
{
	return [NSNumber numberWithInt:apple_identifier];
}

-(double) totalRoyalties
{
	if (!sumsByCurrency)
	{
		[self getTotalsFromCacheIfPossible:YES];
	}
	
	return totalRoyalties;
}

-(NSInteger) totalUnits
{
	if (!sumsByCurrency)
	{
		[self getTotalsFromCacheIfPossible:YES];
	}
	
	return totalUnits;
}



#pragma mark Sorting
- (NSComparisonResult)compareBySales:(Product *)otherProduct
{
	if (self.totalRoyalties < otherProduct.totalRoyalties)
	{
		return NSOrderedDescending;
	}
	
	if (self.totalRoyalties > otherProduct.totalRoyalties)
	{
		return NSOrderedAscending;
	}
	
	return [self.title compare:otherProduct.title];  // if sales equal (maybe 0), sort by name
	//return NSOrderedSame;
}	

#pragma mark Notifications
/*
- (void) updateTotalsFromDict:(NSDictionary *)totalsDict
{
	NSDictionary *tmpDict = [totalsDict objectForKey:@"ByApp"];
	
	NSDictionary *appDict = [tmpDict objectForKey:[self identifierAsNumber]];
	
	totalUnitsSold = [[appDict objectForKey:@"UnitsPaid"] intValue];
	totalUnitsFree = [[appDict objectForKey:@"UnitsFree"] intValue];
	
	sumsByCurrency = [[appDict objectForKey:@"SumsByCurrency"] retain];
	totalRoyalties = [[YahooFinance sharedInstance] convertToEuroFromDictionary:sumsByCurrency];
	
	averageRoyaltiesPerDay = 0; // force recalc on next time it is accessed
}
*/

- (void) exchangeRatesChanged:(NSNotification *)notification
{
	totalRoyalties = [[YahooFinance sharedInstance] convertToEuroFromDictionary:sumsByCurrency];
	
	// force recalc on next time it is accessed
	averageRoyaltiesPerDay = 0; 
	
	totalRoyalties = [[YahooFinance sharedInstance] convertToEuroFromDictionary:sumsByCurrency];
}


#pragma mark Totals and Caching

// save sums to cache
-(void)applicationWillTerminate:(NSNotification *)notification
{
	if (sumsByCurrency)
	{
		/*
		NSString *path = [NSString pathForFileInDocuments:[NSString stringWithFormat:@"%d_sums.dat", apple_identifier]];
		
		NSDictionary *saveDict = [NSDictionary dictionaryWithObjectsAndKeys:sumsByCurrency, @"SumsByCurrency", 
								  [NSNumber numberWithInt:totalUnitsFree], @"TotalUnitsFree",
								  [NSNumber numberWithInt:totalUnitsSold], @"TotalUnitsSold", nil];
		
		[saveDict writeToFile:path atomically:NO];
		*/
		
		NSArray *currencies = [sumsByCurrency allKeys];
		
		sqlite3_stmt *statement;
		
		static char *sql = "REPLACE INTO ProductTotals(product_id, currency, sum_units, sum_royalties) VALUES(?, ?, ?, ?)";
		if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
		
		sqlite3_bind_int(statement, 1, apple_identifier);
		
		for (NSString *oneCurrency in currencies)
		{
			id val = [sumsByCurrency objectForKey:oneCurrency];
			double royalties = 0;
			NSInteger units = 0;
			
			if ([val isKindOfClass:[NSNumber class]])
			{
				royalties = [val doubleValue];
			}
			else
			{
				royalties = [[val objectForKey:@"Royalties"] doubleValue];
				units = [[val objectForKey:@"Units"] intValue];
			}
			
			sqlite3_bind_text(statement, 2, [oneCurrency UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_int(statement, 3, units);
			sqlite3_bind_double(statement, 4, royalties);
			
			int success = sqlite3_step(statement);
			
			NSAssert2((success == SQLITE_OK) || (success >= SQLITE_ROW), @"Error: sqlite3_step failed with error %d (%s).", success, sqlite3_errmsg(database));
			
			sqlite3_reset(statement);
		}
		
		sqlite3_finalize(statement);
		
		
	}
}



-(void)getTotalsFromCacheIfPossible:(BOOL)canUseCache
{
	if (!sumsByCurrency&&canUseCache)
	{
		[self loadSumsFromCache];
		
		if (sumsByCurrency)
		{
			NSLog(@"Loaded sums for %@ from DB", title);
			return;
		}
	}
	
	NSLog(@"Start Totals for %@ %d", title, apple_identifier);
	
	sumsByCurrency = [[NSMutableDictionary alloc] init];
	
	// Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
	if (total_statement == nil) 
	{
		// Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
		// This is a great way to optimize because frequently used queries can be compiled once, then with each
		// use new variable values can be bound to placeholders.
		const char *sql = "SELECT royalty_currency, sum(units), sum(units*royalty_price) FROM report r, sale s WHERE r.id = s.report_id and (type_id=1 or type_id=101) and report_type_id = 0 and app_id = ? group by royalty_currency";
		if (sqlite3_prepare_v2(database, sql, -1, &total_statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
		
	}
	// For this query, we bind the primary key to the first (and only) placeholder in the statement.
	// Note that the parameters are numbered from 1, not from 0.
	
	sqlite3_bind_int(total_statement, 1, apple_identifier);
	
	totalRoyalties = 0;
	totalUnits = 0;
	
	while (sqlite3_step(total_statement) == SQLITE_ROW) 
	{
		NSString *currency_code = [NSString stringWithUTF8String:(char *)sqlite3_column_text(total_statement, 0)];
		NSUInteger units = sqlite3_column_int(total_statement, 1);
		double royalties = sqlite3_column_double(total_statement, 2);
		
		NSMutableDictionary *sumDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:royalties], @"Royalties", 
								 [NSNumber numberWithInt:units], @"Units", nil];
		
		[sumsByCurrency setObject:sumDict forKey:currency_code];
		
		totalUnits += units;
	}
	// Reset the statement for future reuse.
	sqlite3_reset(total_statement);
	
	totalRoyalties = [[YahooFinance sharedInstance] convertToEuroFromDictionary:sumsByCurrency];	
	
	NSLog(@"Stop Totals");
}

-(void)loadSumsFromCache
{
		[sumsByCurrency release];
	sumsByCurrency = nil;
		
		totalRoyalties = 0;
		totalUnits = 0;
		
		sqlite3_stmt *statement;
		
		static char *sql = "SELECT currency, sum_units, sum_royalties FROM ProductTotals where product_id = ?";
		if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) 
		{
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
		
		sqlite3_bind_int(statement, 1, apple_identifier);
		
		while (sqlite3_step(statement) == SQLITE_ROW) 
		{
			NSString *currency = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
			NSInteger units = sqlite3_column_int(statement, 1);
			NSInteger royalties = sqlite3_column_double(statement, 2);
			
			NSMutableDictionary *sumDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:royalties], @"Royalties",
											[NSNumber numberWithInt:units], @"Units", nil];

			
			if (!sumsByCurrency)
			{
				sumsByCurrency = [[NSMutableDictionary alloc] init];
			}
				
			[sumsByCurrency setObject:sumDict forKey:currency];
			totalUnits += units;
		}
		
		if (sumsByCurrency)
		{
			totalRoyalties = [[YahooFinance sharedInstance] convertToEuroFromDictionary:sumsByCurrency];
		}
		
		sqlite3_finalize(statement);
}	

- (void) newReportAdded:(NSNotification *)notification
{
	if (notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		
		BOOL didUpdate = NO;
		
		Report *newReport = [tmpDict objectForKey:@"Report"];
		
		// we're only summing daily reports
		if (newReport.reportType != ReportTypeDay) return;
		
		NSArray *mySales = [newReport.salesByApp objectForKey:[self identifierAsNumber]];

		if (!sumsByCurrency)
		{
			sumsByCurrency = [[NSMutableDictionary alloc] init];
		}
		
		for (Sale *oneSale in mySales)
		{
			if (oneSale.transactionType == TransactionTypeSale || oneSale.transactionType == TransactionTypeIAP)
			{
				NSInteger units = oneSale.unitsSold;
				double royalties = oneSale.unitsSold * oneSale.royaltyPrice;

				totalUnits += units;
				
				NSMutableDictionary *sumDict = [sumsByCurrency objectForKey:oneSale.royaltyCurrency];
				
				didUpdate = YES;
				
				if (!sumDict)
				{
					sumDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:royalties], @"Royalties",
											[NSNumber numberWithInt:units], @"Units", nil];
					
					
					[sumsByCurrency setObject:sumDict forKey:oneSale.royaltyCurrency];
				}
				else
				{
					units += [[sumDict objectForKey:@"Units"] intValue];
					royalties += [[sumDict objectForKey:@"Royalties"] doubleValue];
					
					[sumDict setObject:[NSNumber numberWithInt:units] forKey:@"Units"];
					[sumDict setObject:[NSNumber numberWithDouble:royalties] forKey:@"Royalties"];
				}
				
			}
			
		}
		
		if (didUpdate)
		{
			totalRoyalties = [[YahooFinance sharedInstance] convertToEuroFromDictionary:sumsByCurrency];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AppTotalsUpdated" object:nil userInfo:(id)self];
		}
	} 
}

- (void)emptyCache:(NSNotification *) notification
{
	[sumsByCurrency release];
	sumsByCurrency = nil;
	
	averageRoyaltiesPerDay = 0;
	totalUnits = 0;
	totalRoyalties = 0;
	
	[self getTotalsFromCacheIfPossible:NO];
}

@end

