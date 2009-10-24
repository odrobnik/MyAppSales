//
//  Report.m
//  ASiST
//
//  Created by Oliver Drobnik on 24.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "Report.h"
#import "Sale.h"
#import "CountrySummary.h"
#import "App.h"
#import "Country.h"
#import "Database.h"

#import "YahooFinance.h"

#import "NSString+Helpers.h"
#import "NSDate+Helpers.h"

// Static variables for compiled SQL queries. This implementation choice is to be able to share a one time
// compilation of each query across all instances of the class. Each time a query is used, variables may be bound
// to it, it will be "stepped", and then reset for the next usage. When the application begins to terminate,
// a class method will be invoked to "finalize" (delete) the compiled queries - this must happen before the database
// can be closed.
static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *init_grouping_statement = nil;
static sqlite3_stmt *update_statement = nil;
static sqlite3_stmt *delete_statement = nil;
//static sqlite3_stmt *delete_points_statement = nil;

static sqlite3_stmt *hydrate_statement = nil;
//static sqlite3_stmt *dehydrate_statement = nil;

@implementation Report

@synthesize isNew, sales, salesByApp, summariesByApp;
@synthesize sumUnitsSold,sumUnitsUpdated,sumUnitsRefunded, sumUnitsFree;
@synthesize appsInReport;
@synthesize region, appGrouping;

// Creates the object with primary key and title is brought into memory.
- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    if (self = [super init]) 
	{
        primaryKey = pk;
        database = db;
  
        if (init_statement == nil) 
		{
            const char *sql = "SELECT from_date, until_date, downloaded_date, report_type_id, report_region_id FROM report WHERE report.id=?";
            if (sqlite3_prepare_v2(database, sql, -1, &init_statement, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }
        // For this query, we bind the primary key to the first (and only) placeholder in the statement.
        // Note that the parameters are numbered from 1, not from 0.
        sqlite3_bind_int(init_statement, 1, primaryKey);
        if (sqlite3_step(init_statement) == SQLITE_ROW) 
		{
			self.fromDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 0)]];
			self.untilDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 1)]];
			self.downloadedDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 2)]];
			self.reportType = sqlite3_column_int(init_statement, 3);
			self.region = sqlite3_column_int(init_statement, 4);
        } else {
        }
        // Reset the statement for future reuse.
        sqlite3_reset(init_statement);
		
		if (init_grouping_statement == nil) 
		{
            const char *sql = "SELECT appgrouping_id FROM ReportAppGrouping WHERE report_id=?";
            if (sqlite3_prepare_v2(database, sql, -1, &init_grouping_statement, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }
        // For this query, we bind the primary key to the first (and only) placeholder in the statement.
        // Note that the parameters are numbered from 1, not from 0.
        sqlite3_bind_int(init_grouping_statement, 1, primaryKey);
        if (sqlite3_step(init_grouping_statement) == SQLITE_ROW) 
		{
			NSUInteger groupingID = sqlite3_column_int(init_grouping_statement, 0);
			self.appGrouping = [DB appGroupingForID:groupingID];
        } 
		else 
		{
			[self hydrate];
			
			self.appGrouping = [DB appGroupingForReport:self];
			[self updateInDatabase];
        }
        // Reset the statement for future reuse.
        sqlite3_reset(init_grouping_statement);		
		
		
		
        dirty = NO;
		hydrated = NO;
		
		isNew = NO;
		
		// subscribe to total update notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTotalsUpdated:) name:@"AppTotalsUpdated" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainCurrencyNotification:) name:@"MainCurrencyChanged" object:nil];
		
		
    }
    return self;
}

- (id)initWithType:(ReportType)type from_date:(NSDate *)from_date until_date:(NSDate *)until_date downloaded_date:(NSDate *)downloaded_date region:(ReportRegion)report_region database:(sqlite3 *)db
{
	if (self = [super init])
	{
		database = db;
		self.reportType = type;
		self.fromDate = from_date;  // property copies it anyway, app is "dirty" after setting
		self.untilDate = until_date;
		self.downloadedDate = downloaded_date;
		region = report_region;
		
		[self insertIntoDatabase:database];  // insert into DB right away
		
		hydrated = NO;
		dirty = NO;
		
		isNew = YES;
		
		// subscribe to total update notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTotalsUpdated:) name:@"AppTotalsUpdated" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainCurrencyNotification:) name:@"MainCurrencyChanged" object:nil];
		
		
		return self;
	}
	else
	{
		return nil;
	}
}

// monthly free reports dont have beginning and end dates, thus they need to be supplied
- (id)initAsFreeReportWithDict:(NSDictionary *)dict
{
	if (self = [super init])
	{
		NSDate *fromDateIn = [dict objectForKey:@"FromDate"];
		NSDate *untilDateIn = [dict objectForKey:@"UntilDate"];
		NSString *string = [dict objectForKey:@"Text"];
		
		
		self.fromDate = fromDateIn;
		self.untilDate = untilDateIn;

		// Make a list of apps in this report
		NSMutableSet *tmpAppsInReport = [NSMutableSet set];
		sales = [[NSMutableArray array] retain];
		
		reportType = ReportTypeUnknown;
		self.downloadedDate = [NSDate date];
		
		salesByApp = [[NSMutableDictionary alloc] init];
		summariesByApp = [[NSMutableDictionary alloc] init];
		sumUnitsSold = 0;
		sumUnitsUpdated = 0;
		sumUnitsRefunded = 0;
		
		reportType = ReportTypeFree;
		
		NSArray *lines = [string componentsSeparatedByString:@"\n"];
		NSEnumerator *enu = [lines objectEnumerator];
		NSString *oneLine;
		
		// first line = headers
		oneLine = [enu nextObject];
		NSArray *column_names = [oneLine componentsSeparatedByString:@"\t"];
		
		//	NSString *prev_until_date = @"";
		
		while(oneLine = [enu nextObject])
		{
			NSUInteger appID = [[oneLine getValueForNamedColumn:@"Apple Identifier" headerNames:column_names] intValue];
			NSString *vendor_identifier = [oneLine getValueForNamedColumn:@"Vendor Identifier" headerNames:column_names];
			NSString *company_name = [oneLine getValueForNamedColumn:@"Developer" headerNames:column_names];
			NSString *title	= [oneLine getValueForNamedColumn:@"Title/Application" headerNames:column_names];
			NSUInteger type_id = [[oneLine getValueForNamedColumn:@"Product Type Identifier" headerNames:column_names] intValue];
			NSInteger units = [[oneLine getValueForNamedColumn:@"Units" headerNames:column_names] intValue];
			double royalty_price = [[oneLine getValueForNamedColumn:@"Partner Share" headerNames:column_names] doubleValue];
			NSString *royalty_currency	= [oneLine getValueForNamedColumn:@"Partner Share Currency" headerNames:column_names];
			double customer_price = [[oneLine getValueForNamedColumn:@"Customer Price" headerNames:column_names] doubleValue];
			NSString *customer_currency	= [oneLine getValueForNamedColumn:@"Customer Currency" headerNames:column_names];
			NSString *country_code	= [oneLine getValueForNamedColumn:@"Country Code" headerNames:column_names];
			
			if (fromDateIn&&untilDateIn&&appID&&vendor_identifier&&company_name&&title&&type_id&&units&&royalty_currency&&customer_currency&&country_code)
			{
				Country *saleCountry = [DB countryForCode:country_code];
				saleCountry.usedInReport = YES; // makes sure we have an icon
				
				App *saleApp = [DB appForID:appID];
				
				if (!saleApp)
				{
					saleApp = [DB insertAppWithTitle:title vendor_identifier:vendor_identifier apple_identifier:appID company_name:company_name];
				}
				
				if (![tmpAppsInReport containsObject:saleApp])
				{
					[tmpAppsInReport addObject:saleApp];
				}
				
				
				// detect region for financial reports
				if ((reportType == ReportTypeFinancial)&&(!region))
				{
					region = [saleCountry reportRegion];
				}
				

				
				// add sale
				Sale *newSale = [[Sale alloc] initWithCountry:saleCountry 
													   report:self 
														  app:saleApp 
														units:units 
												 royaltyPrice:royalty_price 
											  royaltyCurrency:royalty_currency 
												customerPrice:customer_price 
											 customerCurrency:customer_currency
											  transactionType:type_id];
				[sales addObject:newSale];
				
				
				
				// sort it into the an index by app
				NSMutableArray *salesForThisAppArray = [salesByApp objectForKey:[NSNumber numberWithInt:appID]];
				
				if (!salesForThisAppArray)
				{
					salesForThisAppArray = [[NSMutableArray alloc] init];
					[salesByApp setObject:salesForThisAppArray forKey:[NSNumber numberWithInt:appID]];
					[salesForThisAppArray release];
				}
				
				[salesForThisAppArray addObject:newSale];
				[newSale release];
				
				// add it to the summaries
				NSMutableDictionary *summaryForThisApp = [summariesByApp objectForKey:[NSNumber numberWithInt:appID]];
				
				if (!summaryForThisApp)
				{ 
					// not yet a summary array for this app
					summaryForThisApp = [[NSMutableDictionary alloc] init];
					[summariesByApp setObject:summaryForThisApp forKey:[NSNumber numberWithInt:appID]];
					[summaryForThisApp release];
				}
				
				// in the summary array we add the current sale's data
				
				CountrySummary *countrySummaryForThisApp = [summaryForThisApp objectForKey:country_code];
				
				if (!countrySummaryForThisApp)
				{
					countrySummaryForThisApp = [[CountrySummary alloc] initWithCountry:saleCountry sumSales:0 sumUpdates:0 sumRefunds:0];
					[summaryForThisApp setObject:countrySummaryForThisApp forKey:country_code];  // just an array, no key for adding
					[countrySummaryForThisApp release];
				}
				
				switch (type_id) {
					case TransactionTypeSale:
					{
						if (units>0)
						{
							countrySummaryForThisApp.sumSales+=units;
							countrySummaryForThisApp.sumRoyalites+= royalty_price*units;
							countrySummaryForThisApp.royaltyCurrency = royalty_currency;
							
							if (royalty_price)
							{
								sumUnitsSold+=units;
							}
							else
							{
								sumUnitsFree+=units;
							}
						}
						else
						{
							countrySummaryForThisApp.sumRefunds +=units;
							sumUnitsRefunded +=units;
						}
						
						break;
					}
					case TransactionTypeFreeUpdate:
					{
						countrySummaryForThisApp.sumUpdates += units;
						sumUnitsUpdated += units;
					}
						
					default:
						break;
				}	
			}
			
		}
		
		hydrated = YES;
		isNew = YES;
		dirty = YES;
		
		// convert to non-mutable
		appsInReport = [[NSSet setWithSet:tmpAppsInReport] retain];
		
	}
	
	return self;
}


- (id)initWithReportText:(NSString *)string
{
	if (self = [super init])
	{
		// Make a list of apps in this report
		NSMutableSet *tmpAppsInReport = [NSMutableSet set];
		sales = [[NSMutableArray array] retain];
		
		reportType = ReportTypeUnknown;
		self.downloadedDate = [NSDate date];

		salesByApp = [[NSMutableDictionary alloc] init];
		summariesByApp = [[NSMutableDictionary alloc] init];
		sumUnitsSold = 0;
		sumUnitsUpdated = 0;
		sumUnitsRefunded = 0;
		
		NSArray *lines = [string componentsSeparatedByString:@"\n"];
		NSEnumerator *enu = [lines objectEnumerator];
		NSString *oneLine;
		
		// first line = headers
		oneLine = [enu nextObject];
		NSArray *column_names = [oneLine componentsSeparatedByString:@"\t"];
		
		// work off all lines
		
		while((oneLine = [enu nextObject])&&[oneLine length])
		{
			NSString *from_date = [oneLine getValueForNamedColumn:@"Begin Date" headerNames:column_names];
			NSString *until_date = [oneLine getValueForNamedColumn:@"End Date" headerNames:column_names];
			NSUInteger appID = [[oneLine getValueForNamedColumn:@"Apple Identifier" headerNames:column_names] intValue];
			NSString *vendor_identifier = [oneLine getValueForNamedColumn:@"Vendor Identifier" headerNames:column_names];
			NSString *company_name = [oneLine getValueForNamedColumn:@"Artist / Show" headerNames:column_names];
			NSString *title	= [oneLine getValueForNamedColumn:@"Title / Episode / Season" headerNames:column_names];
			NSUInteger type_id = [[oneLine getValueForNamedColumn:@"Product Type Identifier" headerNames:column_names] intValue];
			NSInteger units = [[oneLine getValueForNamedColumn:@"Units" headerNames:column_names] intValue];
			double royalty_price = [[oneLine getValueForNamedColumn:@"Royalty Price" headerNames:column_names] doubleValue];
			NSString *royalty_currency	= [oneLine getValueForNamedColumn:@"Royalty Currency" headerNames:column_names];
			double customer_price = [[oneLine getValueForNamedColumn:@"Customer Price" headerNames:column_names] doubleValue];
			NSString *customer_currency	= [oneLine getValueForNamedColumn:@"Customer Currency" headerNames:column_names];
			NSString *country_code	= [oneLine getValueForNamedColumn:@"Country Code" headerNames:column_names];
			
			BOOL financial_report = NO;
			
			if ((!from_date)&&(!company_name)&&(!title)&&(!royalty_currency)&&(!royalty_price)&&(!country_code))
			{
				// probably monthly financial report
				from_date = [oneLine getValueForNamedColumn:@"Start Date" headerNames:column_names];
				
				units = [[oneLine getValueForNamedColumn:@"Quantity" headerNames:column_names] intValue];
				company_name = [oneLine getValueForNamedColumn:@"Artist/Show/Developer" headerNames:column_names];
				title	= [oneLine getValueForNamedColumn:@"Title" headerNames:column_names];
				royalty_currency	= [oneLine getValueForNamedColumn:@"Partner Share Currency" headerNames:column_names];
				royalty_price = [[oneLine getValueForNamedColumn:@"Partner Share" headerNames:column_names] doubleValue];
				country_code	= [oneLine getValueForNamedColumn:@"Country Of Sale" headerNames:column_names];
				
				
				financial_report = YES;
				reportType = ReportTypeFinancial;
			}
			
			// if all columns have a value then we accept the line
			if (from_date&&until_date&&appID&&vendor_identifier&&company_name&&title&&type_id&&units&&royalty_currency&&customer_currency&&country_code)
			{
				Country *saleCountry = [DB countryForCode:country_code];
				saleCountry.usedInReport = YES; // makes sure we have an icon

				App *saleApp = [DB appForID:appID];
				
				if (!saleApp)
				{
					saleApp = [DB insertAppWithTitle:title vendor_identifier:vendor_identifier apple_identifier:appID company_name:company_name];
				}
				
				if (![tmpAppsInReport containsObject:saleApp])
				{
					[tmpAppsInReport addObject:saleApp];
				}
					  
				
				// detect region for financial reports
				if ((reportType == ReportTypeFinancial)&&(!region))
				{
					region = [saleCountry reportRegion];
				}

				// detect report type
				if (reportType == ReportTypeUnknown)
				{
					if ([from_date isEqualToString:until_date])
					{	
						// day report
						reportType = ReportTypeDay;
					}
					else
					{	// week report
						reportType = ReportTypeWeek;
					}
				}
				
				// set report dates if not set
				if (!fromDate&&!untilDate)
				{
					self.fromDate = [from_date dateFromString];
					self.untilDate = [until_date dateFromString];
				}
				
				// add sale
				Sale *newSale = [[Sale alloc] initWithCountry:saleCountry 
													   report:self 
														  app:saleApp 
														units:units 
												 royaltyPrice:royalty_price 
											  royaltyCurrency:royalty_currency 
												customerPrice:customer_price 
											 customerCurrency:customer_currency
											  transactionType:type_id];
				[sales addObject:newSale];


				
				// sort it into the an index by app
				NSMutableArray *salesForThisAppArray = [salesByApp objectForKey:[NSNumber numberWithInt:appID]];
				
				if (!salesForThisAppArray)
				{
					salesForThisAppArray = [[NSMutableArray alloc] init];
					[salesByApp setObject:salesForThisAppArray forKey:[NSNumber numberWithInt:appID]];
					[salesForThisAppArray release];
				}
				
				[salesForThisAppArray addObject:newSale];
				[newSale release];
				
				// add it to the summaries
				NSMutableDictionary *summaryForThisApp = [summariesByApp objectForKey:[NSNumber numberWithInt:appID]];
				
				if (!summaryForThisApp)
				{ 
					// not yet a summary array for this app
					summaryForThisApp = [[NSMutableDictionary alloc] init];
					[summariesByApp setObject:summaryForThisApp forKey:[NSNumber numberWithInt:appID]];
					[summaryForThisApp release];
				}
				
				// in the summary array we add the current sale's data
				
				CountrySummary *countrySummaryForThisApp = [summaryForThisApp objectForKey:country_code];
				
				if (!countrySummaryForThisApp)
				{
					countrySummaryForThisApp = [[CountrySummary alloc] initWithCountry:saleCountry sumSales:0 sumUpdates:0 sumRefunds:0];
					[summaryForThisApp setObject:countrySummaryForThisApp forKey:country_code];  // just an array, no key for adding
					[countrySummaryForThisApp release];
				}
				
				switch (type_id) {
					case TransactionTypeSale:
					{
						if (units>0)
						{
							countrySummaryForThisApp.sumSales+=units;
							countrySummaryForThisApp.sumRoyalites+= royalty_price*units;
							countrySummaryForThisApp.royaltyCurrency = royalty_currency;
							
							if (royalty_price)
							{
								sumUnitsSold+=units;
							}
							else
							{
								sumUnitsFree+=units;
							}
						}
						else
						{
							countrySummaryForThisApp.sumRefunds +=units;
							sumUnitsRefunded +=units;
						}
						
						break;
					}
					case TransactionTypeFreeUpdate:
					{
						countrySummaryForThisApp.sumUpdates += units;
						sumUnitsUpdated += units;
					}
						
					default:
						break;
				}	
			}
				
		}
		
		hydrated = YES;
		isNew = YES;
		dirty = YES;
		
		// convert to non-mutable
		appsInReport = [[NSSet setWithSet:tmpAppsInReport] retain];
	}
	
	return self;
}




- (void)dealloc {
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[appsInReport release];
	[sumsByCurrency release];
	
	[fromDate release];
	[untilDate release];
    [downloadedDate release];
	[salesByApp release];
	[summariesByApp release];
	[sales release];
    [super dealloc];
}

#pragma mark Database
- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO report(from_date, until_date, downloaded_date, report_type_id, report_region_id) VALUES(?, ?, ?, ?, ?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_text(insert_statement, 1, [[fromDate description]UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement, 2, [[untilDate description]UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement, 3, [[downloadedDate description]UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insert_statement, 4, reportType);
    sqlite3_bind_int(insert_statement, 5, region);
	
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
		
		// add sales too
		for (Sale *oneSale in sales)
		{
			[oneSale insertIntoDatabase:database];
		}
		
		// insert the grouping
		[self updateInDatabase];
    }
}


- (void)deleteFromDatabase 
{
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
	
	
	// remove all sales for this report
	sqlite3_stmt *tmp_statement = NULL;
	const char *sql = "DELETE FROM sale WHERE report_id=?";
	
	if (sqlite3_prepare_v2(database, sql, -1, &tmp_statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	else
	{
		// Bind the primary key variable.
		sqlite3_bind_int(tmp_statement, 1, primaryKey);
		// Execute the query.
		success = sqlite3_step(tmp_statement);
		sqlite3_finalize(tmp_statement);
		// Handle errors.
		if (success != SQLITE_DONE) 
		{
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
		}
		
	}
	
	// remove the grouping
	tmp_statement = NULL;
	const char *sql2 = "DELETE FROM ReportAppGrouping WHERE report_id=?";
	
	if (sqlite3_prepare_v2(database, sql2, -1, &tmp_statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	else
	{
		// Bind the primary key variable.
		sqlite3_bind_int(tmp_statement, 1, primaryKey);
		// Execute the query.
		success = sqlite3_step(tmp_statement);
		sqlite3_finalize(tmp_statement);
		// Handle errors.
		if (success != SQLITE_DONE) 
		{
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
		}
	}
}

// only the grouping is to be updated
- (void)updateInDatabase 
{
    // Compile the delete statement if needed.
    if (update_statement == nil) 
	{
        const char *sql = "REPLACE INTO  ReportAppGrouping (report_id, appgrouping_id) values (?, ?)";
        if (sqlite3_prepare_v2(database, sql, -1, &update_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_int(update_statement, 1, primaryKey);
    sqlite3_bind_int(update_statement, 2, appGrouping.primaryKey);
    // Execute the query.
    int success = sqlite3_step(update_statement);
    // Reset the statement for future use.
    sqlite3_reset(update_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to update in database with message '%s'.", sqlite3_errmsg(database));
    }
}


- (void) makeSummariesFromSales
{
	// reset
	
	if (!summariesByApp)
	{
		summariesByApp = [[NSMutableDictionary alloc] init];
	}
	else
	{
		[summariesByApp removeAllObjects];
	}
	
	sumUnitsSold = 0;
	sumUnitsUpdated = 0;
	sumUnitsRefunded = 0;
	
	
	
	// go through all sales
	
	for (Sale *oneSale in sales)
	{
		NSUInteger app_id = oneSale.app.apple_identifier;
		NSString *cntry_code = oneSale.country.iso2;
		Country *country = oneSale.country;
		NSUInteger ttype = oneSale.transactionType;
		NSInteger units = oneSale.unitsSold;
		double royalty_price = oneSale.royaltyPrice;
		NSString *royalty_currency = oneSale.royaltyCurrency;
		//double customer_price = oneSale.customerPrice;
		//NSString *customer_currency = oneSale.customerCurrency;
		
		
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
					
					if (royalty_price)
					{
						sumUnitsSold+=units;
					}
					else
					{
						sumUnitsFree+=units;
					}
					
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
}





// get all detail info
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
	else
	{
		[salesByApp removeAllObjects];
	}
	
	NSMutableSet *tmpAppsInReport = [NSMutableSet set];

	
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
		
		Country *country = [DB countryForCode:cntry_code];
		country.usedInReport = YES; // makes sure we have an icon
		
		// detect region for financial reports
		if ((reportType == ReportTypeFinancial)&&(!region))
		{
			region = [country reportRegion];
		}
		
		App *app = [DB appForID:app_id];
		if (![tmpAppsInReport containsObject:app])
		{
			[tmpAppsInReport addObject:app];
		}
		
		Sale *tmpSale = [[Sale alloc] initWithCountry:country report:self app:app units:units royaltyPrice:royalty_price royaltyCurrency:royalty_currency customerPrice:customer_price customerCurrency:customer_currency transactionType:ttype];
		
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
	}
	// Reset the statement for future reuse.
	sqlite3_reset(hydrate_statement);
	
	[self makeSummariesFromSales];
	
	hydrated = YES;
	
	// sums are dependent on exchange rates, if they change we need to redo the sums
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRatesChanged:) name:@"ExchangeRatesChanged" object:nil];

	// convert to non-mutable
	appsInReport = [[NSSet setWithSet:tmpAppsInReport] retain];
	
	self.appGrouping = [DB appGroupingForReport:self];
}

// remove detail info from memory
- (void) dehydrate
{
	[salesByApp release];
	salesByApp = nil;
	
	[sales release];
	sales = nil;
	
	[summariesByApp release];
	summariesByApp = nil;
	
	hydrated = NO;
}

#pragma mark Utilities
- (NSDate *)dateInMiddleOfReport
{
	// calculate the middle point and output it's localized name
	NSTimeInterval start = [fromDate timeIntervalSince1970];
	NSTimeInterval finish = [untilDate timeIntervalSince1970];
	NSTimeInterval middle = (start + finish)/2.0;
	
	return [NSDate dateWithTimeIntervalSince1970:middle];
}

- (NSString *)monthForMonthlyReports
{
	NSDate *tmpDate = [self dateInMiddleOfReport];
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateFormat:@"MMMM YYYY"];
	
	return [df stringFromDate:tmpDate];
}

- (NSString *)descriptionFinancialShort
{
	NSString *region_name;
	
	switch (region) {
		case ReportRegionUK:
			region_name = @"UK";
			break;
		case ReportRegionUSA:
			region_name = @"US";
			break;
		case ReportRegionEurope:
			region_name = @"EU";
			break;
		case ReportRegionJapan:
			region_name = @"JP";
			break;
		case ReportRegionCanada:
			region_name = @"CA";
			break;
		case ReportRegionAustralia:
			region_name = @"AU";
			break;
		case ReportRegionRestOfWorld:
			region_name = @"WW";
			break;
		default:
			region_name = @"??";
	}
	
	NSDate *tmpDate = [self dateInMiddleOfReport];
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateFormat:@"MM/YYYY"];
	
	NSString *monthString = [df stringFromDate:tmpDate];
	return [NSString stringWithFormat:@"%@ %@", region_name, monthString];
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
		case ReportTypeFree:
		{
			return [self monthForMonthlyReports];
			break;
		}
		case ReportTypeFinancial:
		{
			NSString *region_name;
			
			//[self hydrate];  // to estimate the region until there is a table for it
			
			switch (region) {
				case ReportRegionUK:
					region_name = @"UK";
					break;
				case ReportRegionUSA:
					region_name = @"USA";
					break;
				case ReportRegionEurope:
					region_name = @"Europe";
					break;
				case ReportRegionJapan:
					region_name = @"Japan";
					break;
				case ReportRegionCanada:
					region_name = @"Canada";
					break;
				case ReportRegionAustralia:
					region_name = @"Australia";
					break;
				case ReportRegionRestOfWorld:
					region_name = @"Rest";
					break;
				default:
					region_name = @"Invalid Region";
			}
			
			return [NSString stringWithFormat:@"%@ %@", [self monthForMonthlyReports], region_name];
			break;
		}
			
			
		default:
			return [fromDate description];
			break;
	}
	
}

- (NSString *)description
{
	return [self listDescription];
}

- (NSUInteger) day
{
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *comps = [gregorian components:NSDayCalendarUnit fromDate:self.fromDate];
	return comps.day;
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


#pragma mark Sums
- (NSInteger) sumUnitsForAppId:(NSUInteger)app_id transactionType:(TransactionType)ttype
{
	NSMutableArray *tmpArray = [salesByApp objectForKey:[NSNumber numberWithInt:app_id]];
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

- (double) sumRoyaltiesForAppId:(NSUInteger)app_id transactionType:(TransactionType)ttype
{
	NSMutableArray *tmpArray = [salesByApp objectForKey:[NSNumber numberWithInt:app_id]];
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

- (double) sumRoyaltiesForAppId:(NSUInteger)app_id inCurrency:(NSString *)curCode
{
	NSMutableArray *tmpArray = [salesByApp objectForKey:[NSNumber numberWithInt:app_id]];
	double ret = 0;
	
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
		ret += [self sumRoyaltiesForAppId:[oneKey intValue] inCurrency:@"EUR"];   // internally all is Euro
	}
	
	// cache it
	sumRoyaltiesEarned = ret;
	return ret;
}

- (NSInteger) sumRefundsForAppId:(NSUInteger)app_id
{
	NSMutableArray *tmpArray = [salesByApp objectForKey:[NSNumber numberWithInt:app_id]];
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

#pragma mark Sorting
- (NSComparisonResult)compareByReportDateDesc:(Report *)otherObject
{
	NSTimeInterval diff = [fromDate timeIntervalSinceDate:otherObject.fromDate];
	if (diff<0)
	{
		return NSOrderedDescending;
	}
	
	if (diff>0)
	{
		return NSOrderedAscending;
	}
	
	return NSOrderedSame;
}

#pragma mark Notifications
- (void)appTotalsUpdated:(NSNotification *) notification
{
	if(notification)
	{
		NSDictionary *tmpDict = [[notification userInfo] objectForKey:@"ByReport"];
		
		NSDictionary *reportDict = [tmpDict objectForKey:[NSNumber numberWithInt:primaryKey]];
		
		sumUnitsSold = [[reportDict objectForKey:@"UnitsPaid"] intValue];
		sumUnitsFree = [[reportDict objectForKey:@"UnitsFree"] intValue];
		
		sumsByCurrency = [[reportDict objectForKey:@"SumsByCurrency"] retain];
		
		sumRoyaltiesEarned = [[YahooFinance sharedInstance] convertToEuroFromDictionary:sumsByCurrency];	
	}
}

- (void)mainCurrencyNotification:(NSNotification *) notification
{
	// don't need to do anything
}

- (void)exchangeRatesChanged:(NSNotification *) notification
{
	sumRoyaltiesEarned = 0;  // forces recalculation of this sum on next call
}


#pragma mark MyAppSales Web Service

// notify the server anonymously about the availability of all reports
- (void) notifyServerAboutReportAvailability
{
	// build URL
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateFormat:@"YYYY-MM-dd"];
	
	NSString *reportDateString = [df stringFromDate:untilDate];
	NSString *url_string = [NSString stringWithFormat:@"http://www.drobnik.com/services/myappsales.asmx/SeenReport?ReportType=%d&ReportDate=%@&ReportRegionID=%d", reportType, reportDateString, region];
	NSURL *url = [NSURL URLWithString:url_string];
	
	NSURLRequest *request=[NSURLRequest requestWithURL:url
										   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
									   timeoutInterval:60.0];
	
	[[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease]; // we don't care about reponse
}


@end
