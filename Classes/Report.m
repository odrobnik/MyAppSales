//
//  Report.m
//  ASiST
//
//  Created by Oliver Drobnik on 24.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Report.h"
#import "Sale.h"
#import "CountrySummary.h"
#import "App.h"
#import "Country.h"

#import "YahooFinance.h"
#import "BirneConnect.h"

// Static variables for compiled SQL queries. This implementation choice is to be able to share a one time
// compilation of each query across all instances of the class. Each time a query is used, variables may be bound
// to it, it will be "stepped", and then reset for the next usage. When the application begins to terminate,
// a class method will be invoked to "finalize" (delete) the compiled queries - this must happen before the database
// can be closed.
static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *delete_statement = nil;
//static sqlite3_stmt *delete_points_statement = nil;

static sqlite3_stmt *hydrate_statement = nil;
//static sqlite3_stmt *dehydrate_statement = nil;

// Date formatter for XML files
static NSDateFormatter *dateFormatterToRead = nil;

@implementation Report

@synthesize isNew, sales, salesByApp, summariesByApp; //, countrySummaries;

@synthesize sumUnitsSold,sumUnitsUpdated,sumUnitsRefunded, itts;

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
    if (self = [super init]) 
	{
        primaryKey = pk;
        database = db;
        // Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
        if (init_statement == nil) {
            // Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
            // This is a great way to optimize because frequently used queries can be compiled once, then with each
            // use new variable values can be bound to placeholders.
            const char *sql = "SELECT from_date, until_date, downloaded_date, report_type_id FROM report WHERE id=?";
            if (sqlite3_prepare_v2(database, sql, -1, &init_statement, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }
        // For this query, we bind the primary key to the first (and only) placeholder in the statement.
        // Note that the parameters are numbered from 1, not from 0.
        sqlite3_bind_int(init_statement, 1, primaryKey);
        if (sqlite3_step(init_statement) == SQLITE_ROW) 
		{
			self.fromDate = [self dateFromString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 0)]];
			self.untilDate = [self dateFromString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 1)]];
			self.downloadedDate = [self dateFromString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 2)]];
			self.reportType = sqlite3_column_int(init_statement, 3);
        } else {
        }
        // Reset the statement for future reuse.
        sqlite3_reset(init_statement);
        dirty = NO;
		hydrated = NO;
		
		isNew = NO;
    }
    return self;
}

- (id)initWithType:(ReportType)type from_date:(NSDate *)from_date until_date:(NSDate *)until_date downloaded_date:(NSDate *)downloaded_date database:(sqlite3 *)db
{
	if (self = [super init])
	{
		database = db;
		self.reportType = type;
		self.fromDate = from_date;  // property copies it anyway, app is "dirty" after setting
		self.untilDate = until_date;
		self.downloadedDate = downloaded_date;
			
		[self insertIntoDatabase:database];  // insert into DB right away
		
		hydrated = NO;
		dirty = NO;
		return self;
	}
	else
	{
		return nil;
	}
}

- (void)dealloc {
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[itts release];
	[fromDate release];
	[untilDate release];
    [downloadedDate release];
	[salesByApp release];
	[summariesByApp release];
	[sales release];
    [super dealloc];
}

- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO report(from_date, until_date, downloaded_date, report_type_id) VALUES(?, ?, ?, ?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_text(insert_statement, 1, [[fromDate description]UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement, 2, [[untilDate description]UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement, 3, [[downloadedDate description]UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insert_statement, 4, reportType);
	
    int success = sqlite3_step(insert_statement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insert_statement);
    if (success == SQLITE_ERROR) {
        NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
    } else {
        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
        // in the database. To access this functionality, the table should have a column declared of type 
        // "INTEGER PRIMARY KEY"
        
		 primaryKey = sqlite3_last_insert_rowid(database);
    }
    // All data for the book is already in memory, but has not be written to the database
    // Mark as hydrated to prevent empty/default values from overwriting what is in memory
    //hydrated = YES;
}

- (void)deleteFromDatabase {
    // Compile the delete statement if needed.
    if (delete_statement == nil) {
        const char *sql = "DELETE FROM report WHERE id=?";
        if (sqlite3_prepare_v2(database, sql, -1, &delete_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_int(delete_statement, 1, primaryKey);
    // Execute the query.
    int success = sqlite3_step(delete_statement);
    // Reset the statement for future use.
    sqlite3_reset(delete_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
    }
}


- (NSString *)listDescription
{
		switch (reportType) {
			case ReportTypeDay:
			{
				NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
				[formatter setDateStyle:NSDateFormatterLongStyle];
				[formatter setTimeStyle:NSDateFormatterNoStyle];
				return [formatter stringFromDate:fromDate];
				break;
			}
			case ReportTypeWeek:
			{
				NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
//				[formatter setDateFormat:@"'Week' w, yyyy"];
				[formatter setDateStyle:NSDateFormatterShortStyle];
				[formatter setTimeStyle:NSDateFormatterNoStyle];
				return [NSString stringWithFormat:@"%@ until %@",[formatter stringFromDate:fromDate], [formatter stringFromDate:untilDate]];
				break;
			}
			default:
				return [fromDate description];
				break;
		}
	
}



- (NSString *) reconstructText
{
	[self hydrate];  // to load all infos necessary
	
	NSMutableString *ret = [[NSMutableString alloc] init];

	[ret appendString:@"Provider	Provider Country	Vendor Identifier	UPC	ISRC	Artist / Show	Title / Episode / Season	Label/Studio/Network	Product Type Identifier	Units	Royalty Price	Begin Date	End Date	Customer Currency	Country Code	Royalty Currency	Preorder	Season Pass	ISAN	Apple Identifier	Customer Price	CMA	Asset/Content Flavor\r\n"];
	
	
	
	NSEnumerator *enu = [sales objectEnumerator];
	Sale *oneSale;
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"MM/dd/yyyy"];
	//[df setDateStyle:NSDateFormatterShortStyle];
	
	while (oneSale = [enu nextObject])
	{
		// one report line
		
		App *tmpApp = oneSale.app;
		[ret appendFormat:@"APPLE\tUS\t%@\t\t\t%@\t%@\t\t%d\t%d\t%.2f\t%@\t%@\t%@\t%@\t%@\t\t\t\t%d\t%.2f\t\t\r\n", tmpApp.vendor_identifier, tmpApp.company_name, tmpApp.title, 
		 (int)oneSale.transactionType, oneSale.unitsSold, oneSale.royaltyPrice, [df stringFromDate:fromDate], [df stringFromDate:untilDate], oneSale.customerCurrency, oneSale.country.iso2,
		oneSale.royaltyCurrency, oneSale.app.apple_identifier, oneSale.customerPrice];
	}
	
	[df release];

	NSString *retStatic = [NSString stringWithString:ret];
	[ret release];
	
	return retStatic;
	
	
   //select 'APPLE','US', vendor_identifier, '','',company_name, app.title, type_id, units, royalty_price, from_date, until_date, customer_currency, country_code, royalty_currency,'','', app.id, customer_price, '', '' from app, report, sale where app.id = sale.app_id and sale.report_id = report.id and report_id = 1;
	
/*	
	if (!countries)
	{
		countries = [[NSMutableDictionary alloc] init];
	}
	sqlite3_stmt *statement = nil;
	const char *sql = "select 'APPLE','US', vendor_identifier, i'','',company_name, app.title, type_id, units, royalty_price, from_date, until_date, customer_currency, country_code, royalty_currency,'','', app.id, customer_price, '', '' from app, report, sale where app.id = sale.app_id and sale.report_id = report.id and report_id = ?;";
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		
	}
	
	sqlite3_bind_int(statement, 1, primaryKey);

	while (sqlite3_step(statement) == SQLITE_ROW) 
	{
		NSString *cntry = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
		Country *tmpCountry = [[Country alloc] initWithISO3:cntry database:database];
		[countries setObject:tmpCountry forKey:tmpCountry.iso2],
		[tmpCountry release];
	} 
	
	// Finalize the statement, no reuse.
	sqlite3_finalize(statement);
	
	*/
	
	return @"";
	
}


- (void) hydrate
{
	if (hydrated)
	{
		return;
	}
	
	if (!sales)
	{
		sales = [[NSMutableArray alloc] init];
	}
	
	if (!salesByApp)
	{
		salesByApp = [[NSMutableDictionary alloc] init];
	}
	
	if (!summariesByApp)
	{
		summariesByApp = [[NSMutableDictionary alloc] init];
	}
	
	sumUnitsSold = 0;
	sumUnitsUpdated = 0;
	sumUnitsRefunded = 0;
		
	// Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
	if (hydrate_statement == nil) 
	{
		// Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
		// This is a great way to optimize because frequently used queries can be compiled once, then with each
		// use new variable values can be bound to placeholders.
		const char *sql = "SELECT country_code, units, app_id, royalty_price, royalty_currency,type_id,customer_price, customer_currency FROM sale WHERE report_id=?";  //  order by units desc <- done by view
		if (sqlite3_prepare_v2(database, sql, -1, &hydrate_statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
	}
	// For this query, we bind the primary key to the first (and only) placeholder in the statement.
	// Note that the parameters are numbered from 1, not from 0.
	sqlite3_bind_int(hydrate_statement, 1, primaryKey);
	

	
	while (sqlite3_step(hydrate_statement) == SQLITE_ROW) 
	{
		NSString *cntry_code = [NSString stringWithUTF8String:(char *)sqlite3_column_text(hydrate_statement, 0)];
		NSInteger units = (int)sqlite3_column_int(hydrate_statement, 1);
		NSInteger app_id = (int)sqlite3_column_int(hydrate_statement, 2);
		double royalty_price = (double)sqlite3_column_double(hydrate_statement, 3);
		NSString *royalty_currency = [NSString stringWithUTF8String:(char *)sqlite3_column_text(hydrate_statement, 4)];
		NSInteger ttype = (int)sqlite3_column_int(hydrate_statement, 5);
		double customer_price = (double)sqlite3_column_double(hydrate_statement, 6);
		NSString *customer_currency = [NSString stringWithUTF8String:(char *)sqlite3_column_text(hydrate_statement, 7)];

		Country *country = [itts.countries objectForKey:cntry_code];
		country.usedInReport = YES; // makes sure we have an icon
		
		App *app = [itts.apps objectForKey:[NSNumber numberWithInt:app_id]];
		
		Sale *tmpSale = [[Sale alloc] initWithCountryCode:country app:app units:units royaltyPrice:royalty_price royaltyCurrency:royalty_currency customerPrice:customer_price customerCurrency:customer_currency transactionType:ttype];
		[sales addObject:tmpSale];
		
		NSMutableArray *tmpArray = [salesByApp objectForKey:[NSNumber numberWithInt:app_id]];
		
		if (!tmpArray)
		{
			tmpArray = [[NSMutableArray alloc] init];
			[salesByApp setObject:tmpArray forKey:[NSNumber numberWithInt:app_id]];
			[tmpArray release];
		}
		
		[tmpArray addObject:tmpSale];
		[tmpSale release];
		
		
		// create a summary by app
		
		// 1) get or create app 
		NSMutableDictionary *tmpSummaries = [summariesByApp objectForKey:[NSNumber numberWithInt:app_id]];
		
		if (!tmpSummaries)
		{  // not yet a summary array for this app
			tmpSummaries = [[NSMutableDictionary alloc] init];
			[summariesByApp setObject:tmpSummaries forKey:[NSNumber numberWithInt:app_id]];
			[tmpSummaries release];
		}
		
		// 2) in the summary array we add the current sale's data
		
		CountrySummary *tmpSummary = [tmpSummaries objectForKey:cntry_code];
		
		if (!tmpSummary)
		{
			tmpSummary = [[CountrySummary alloc] initWithCountry:country sumSales:0 sumUpdates:0 sumRefunds:0];
			[tmpSummaries setObject:tmpSummary forKey:cntry_code];  // just an array, no key for adding
			[tmpSummary release];
		}
		
		switch (ttype) {
			case TransactionTypeSale:
			{
				if (units>0)
				{
					tmpSummary.sumSales+=units;
					tmpSummary.sumRoyalites+= royalty_price*units;
					tmpSummary.royaltyCurrency = royalty_currency;
					sumUnitsSold+=units;
					
				}
				else
				{
					tmpSummary.sumRefunds +=units;
					sumUnitsRefunded +=units;
				}
				
				
				// get's calculated when needed
				//sumRoyaltiesEarned += [[YahooFinance sharedInstance] convertToEuro:(royalty_price*units) fromCurrency:royalty_currency]; 
				

				break;
			}
			case TransactionTypeFreeUpdate:
			{
				tmpSummary.sumUpdates += units;
				sumUnitsUpdated += units;
			}
				
			default:
				break;
		}		
		
	}
	// Reset the statement for future reuse.
	sqlite3_reset(hydrate_statement);
	
	hydrated = YES;
	
	// sums are dependent on exchange rates, if they change we need to redo the sums
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRatesChanged:) name:@"ExchangeRatesChanged" object:nil];
	
	
}


- (NSInteger) sumUnitsForAppId:(NSNumber *)app_id transactionType:(TransactionType)ttype
{
	NSMutableArray *tmpArray = [salesByApp objectForKey:app_id];
	NSInteger ret = 0;
	
	if (tmpArray)
	{
		NSEnumerator *en = [tmpArray objectEnumerator];
		Sale *aSale;
		
		while (aSale = [en nextObject]) 
		{
			if ((ttype==aSale.transactionType)&&(aSale.unitsSold>0))
			{
				ret += aSale.unitsSold;
			}
		}
	}
	
	
	return ret;
}

- (double) sumRoyaltiesForAppId:(NSNumber *)app_id transactionType:(TransactionType)ttype
{
	NSMutableArray *tmpArray = [salesByApp objectForKey:app_id];
	double ret = 0;

	if (tmpArray)
	{
		
		NSEnumerator *en = [tmpArray objectEnumerator];
		Sale *aSale;
		
		while (aSale = [en nextObject]) 
		{
			ret += [[YahooFinance sharedInstance] convertToEuro:(aSale.royaltyPrice * aSale.unitsSold) fromCurrency:aSale.royaltyCurrency]; 
		}
	}
	
	return ret;
}

- (double) sumRoyaltiesForAppId:(NSNumber *)app_id inCurrency:(NSString *)curCode
{
	NSMutableArray *tmpArray = [salesByApp objectForKey:app_id];
	double ret = 0;
	NSLog(@"---");
	
	if (tmpArray)
	{
		
		NSEnumerator *en = [tmpArray objectEnumerator];
		Sale *aSale;
		
		while (aSale = [en nextObject]) 
		{
			ret += [[YahooFinance sharedInstance] convertToCurrency:curCode amount:(aSale.royaltyPrice * aSale.unitsSold) fromCurrency:aSale.royaltyCurrency];
		}
	}
	
	return ret;
}

// override property
- (double) sumRoyaltiesEarned
{
	// if we cached the value then return it, otherwise calculate it
	if (sumRoyaltiesEarned)
	{
		return sumRoyaltiesEarned;
	}
	
	double ret = 0;
	
	for (NSNumber *oneKey in [salesByApp allKeys])
	{
		ret += [self sumRoyaltiesForAppId:oneKey inCurrency:[[YahooFinance sharedInstance] mainCurrency]];
	}
	
	// cache it
	sumRoyaltiesEarned = ret;
	return ret;
}

- (NSInteger) sumRefundsForAppId:(NSNumber *)app_id
{
	NSMutableArray *tmpArray = [salesByApp objectForKey:app_id];
	NSInteger ret = 0;
	
	if (tmpArray)
	{
		NSEnumerator *en = [tmpArray objectEnumerator];
		Sale *aSale;
		
		while (aSale = [en nextObject]) 
		{
			if ((aSale.transactionType==TransactionTypeSale)&&(aSale.unitsSold<0))
			{
				ret += aSale.unitsSold;
			}
		}
	}
	
	
	return ret;
}

#pragma mark Properties
// Accessors implemented below. All the "get" accessors simply return the value directly, with no additional
// logic or steps for synchronization. The "set" accessors attempt to verify that the new value is definitely
// different from the old value, to minimize the amount of work done. Any "set" which actually results in changing
// data will mark the object as "dirty" - i.e., possessing data that has not been written to the database.
// All the "set" accessors copy data, rather than retain it. This is common for value objects - strings, numbers, 
// dates, data buffers, etc. This ensures that subsequent changes to either the original or the copy don't violate 
// the encapsulation of the owning object.

- (NSUInteger)primaryKey {
    return primaryKey;
}

- (ReportType)reportType {
    return reportType;
}

- (void)setReportType:(ReportType)aReportType 
{
    if (reportType == aReportType) return;
    dirty = YES;
    reportType = aReportType;
}

- (NSDate *)fromDate {
    return fromDate;
}

- (void)setFromDate:(NSDate *)aDate {
    if ((!fromDate && !aDate) || (fromDate && aDate && [fromDate isEqualToDate:aDate])) return;
    dirty = YES;
    [fromDate release];
    fromDate = [aDate copy];
}

- (NSDate *)untilDate {
    return untilDate;
}

- (void)setUntilDate:(NSDate *)aDate {
    if ((!untilDate && !aDate) || (untilDate && aDate && [untilDate isEqualToDate:aDate])) return;
    dirty = YES;
    [untilDate release];
    untilDate = [aDate copy];
}

- (NSDate *)downloadedDate {
    return downloadedDate;
}

- (void)setDownloadedDate:(NSDate *)aDate {
    if ((!downloadedDate && !aDate) || (downloadedDate && aDate && [downloadedDate isEqualToDate:aDate])) return;
    dirty = YES;
    [downloadedDate release];
    downloadedDate = [aDate copy];
}

- (void)exchangeRatesChanged:(NSNotification *) notification
{
	sumRoyaltiesEarned = 0;
}

@end
