//
//  Report.m
//  ASiST
//
//  Created by Oliver Drobnik on 24.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "Report_v1.h"
#import "Sale_v1.h"
#import "CountrySummary.h"
#import "App.h"
#import "Product_v1.h"
#import "InAppPurchase.h"
#import "InAppPurchase.h"
#import "Country_v1.h"
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
//static sqlite3_stmt *init_grouping_statement = nil;
static sqlite3_stmt *update_statement = nil;
static sqlite3_stmt *delete_statement = nil;
//static sqlite3_stmt *delete_points_statement = nil;

static sqlite3_stmt *hydrate_statement = nil;
//static sqlite3_stmt *dehydrate_statement = nil;

@interface Report_v1 ()  // private

-(void)resetSummaries;
- (void) addSaleToSummaries:(Sale_v1 *)oneSale;

@end

@implementation Report_v1

@synthesize isNew, sales, salesByApp, summariesByApp;
@synthesize sumUnitsSold,sumUnitsUpdated,sumUnitsRefunded, sumUnitsFree;
@synthesize appsInReport;
@synthesize region, appGrouping;


#pragma mark Initialization

// bulk load experiment

-(id)init
{
	if ((self = [super init]))
	{
		dirty = NO;
		hydrated = NO;
		
		isNew = NO;
		
		// subscribe to total update notifications
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTotalsUpdated:) name:@"AppTotalsUpdated" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainCurrencyNotification:) name:@"MainCurrencyChanged" object:nil];
	}
	
	return self;
}


- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db fromDate:(NSDate *)aFromDate untilDate:(NSDate *)aUntilDate aDownloadedDate:(NSDate *)aDownloadedDate reportTypeID:(ReportType)reportTypeID reportRegionID:(ReportRegion)reportRegionID appGroupingID:(NSUInteger)appGroupingID
{
	if ((self = [self init]))
	{
        primaryKey = pk;
        database = db;
		
		if (aFromDate)
		{
			self.fromDate = aFromDate;
		}
		else
		{
			NSLog(@"Encountered NULL fromDate in report with ID %d", primaryKey);
			[self release];
			return nil;
		}
		
		
		if (aUntilDate)
		{
			self.untilDate = aUntilDate;
		}
		else
		{
			NSLog(@"Encountered NULL untilDate in report with ID %d", primaryKey);
			[self release];
			return nil;
		}
		
		if (aDownloadedDate)
		{
			self.downloadedDate = aDownloadedDate;
		}
		else
		{
			NSLog(@"Encountered NULL downloadedDate in report with ID %d", primaryKey);
			[self release];
			return nil;
		}
		
		self.reportType = reportTypeID;
		self.region = reportRegionID;
		
		self.appGrouping = [DB appGroupingForID:appGroupingID];
		
		if (!appGrouping)
		{
			[self hydrate];
			
			self.appGrouping = [DB appGroupingForReport:self];
			[self updateInDatabase];
		}
		
	}
	
	return self;
}


// Creates the object with primary key and title is brought into memory.
- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    if ((self = [self init]))
	{
        primaryKey = pk;
        database = db;
		
        if (init_statement == nil) 
		{
            const char *sql = "SELECT from_date, until_date, downloaded_date, report_type_id, report_region_id, appgrouping_id from report where report.id = ?;";
            if (sqlite3_prepare_v2(database, sql, -1, &init_statement, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }
        // For this query, we bind the primary key to the first (and only) placeholder in the statement.
        // Note that the parameters are numbered from 1, not from 0.
        sqlite3_bind_int(init_statement, 1, primaryKey);
        if (sqlite3_step(init_statement) == SQLITE_ROW) 
		{
			char *from_date = (char *)sqlite3_column_text(init_statement, 0);
			
			if (from_date)
			{
				self.fromDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:from_date]];
			}
			else
			{
				NSLog(@"Encountered NULL fromDate in report with ID %d", primaryKey);
				[self release];
				return nil;
			}
			
			
			char *until_date = (char *)sqlite3_column_text(init_statement, 1);
			
			if (until_date)
			{
				self.untilDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:until_date]];
			}
			else
			{
				NSLog(@"Encountered NULL untilDate in report with ID %d", primaryKey);
				[self release];
				return nil;
			}
			
			char *downloaded_date = (char *)sqlite3_column_text(init_statement, 2);
			
			if (downloaded_date)
			{
				self.downloadedDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:downloaded_date]];
			}
			else
			{
				NSLog(@"Encountered NULL downloadedDate in report with ID %d", primaryKey);
				[self release];
				return nil;
			}
			
			self.reportType = sqlite3_column_int(init_statement, 3);
			self.region = sqlite3_column_int(init_statement, 4);
			
			NSUInteger groupingID = sqlite3_column_int(init_statement, 5);
			
			self.appGrouping = [DB appGroupingForID:groupingID];
			
			if (!appGrouping)
			{
				[self hydrate];
				
				self.appGrouping = [DB appGroupingForReport:self];
				[self updateInDatabase];
			}
        }
		
        // Reset the statement for future reuse.
        sqlite3_reset(init_statement);
    }
    return self;
}

// monthly free reports dont have beginning and end dates, thus they need to be supplied
- (id)initAsFreeReportWithDict:(NSDictionary *)dict
{
	if ((self = [self init]))
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
		
		[self resetSummaries];
		
		reportType = ReportTypeFree;
		
		NSArray *lines = [string componentsSeparatedByString:@"\n"];
		NSEnumerator *enu = [lines objectEnumerator];
		NSString *oneLine;
		
		// first line = headers
		oneLine = [enu nextObject];
		NSArray *column_names = [oneLine arrayOfColumnNames];
		
		//	NSString *prev_until_date = @"";
		
		while ((oneLine = [enu nextObject]))
		{
			NSString *appIDString = [oneLine getValueForNamedColumn:@"Apple Identifier" headerNames:column_names];
			NSUInteger appID = [appIDString intValue];
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
			
			
			// filter if PARTNERVERSION is active
#ifdef PARTNERVERSION
			NSSet *onlyThese = PARTNERVERSION_FILTER_APPS_SET;
			if (![onlyThese containsObject:appIDString])
			{
				appID=0; // causes this line to be ignored
			}
#endif
			
			if (fromDateIn&&untilDateIn&&appID&&vendor_identifier&&company_name&&title&&type_id&&units&&royalty_currency&&customer_currency&&country_code)
			{
				Country_v1 *saleCountry = [DB countryForCode:country_code];
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
				Sale_v1 *newSale = [[Sale_v1 alloc] initWithCountry:saleCountry 
															 report:self 
															product:saleApp 
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
				
				[self addSaleToSummaries:newSale];
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
	if ((self = [super init]))
	{
		// Make a list of apps in this report
		NSMutableSet *tmpAppsInReport = [NSMutableSet set];
		sales = [[NSMutableArray array] retain];
		
		reportType = ReportTypeUnknown;
		self.downloadedDate = [NSDate date];
		
		salesByApp = [[NSMutableDictionary alloc] init];
		
		[self resetSummaries];
		
		NSArray *lines = [string componentsSeparatedByString:@"\n"];
		NSEnumerator *enu = [lines objectEnumerator];
		NSString *oneLine;
		
		// first line = headers
		oneLine = [enu nextObject];
		NSArray *column_names = [oneLine arrayOfColumnNames];
		
		// work off all lines
		
		while((oneLine = [enu nextObject])&&[oneLine length])
		{
			NSString *from_date = [oneLine getValueForNamedColumn:@"Begin Date" headerNames:column_names];
			
			/*
			 if (!from_date)
			 {
			 // ITC Format as of Sept 2010
			 from_date = [oneLine getValueForNamedColumn:@"Start Date" headerNames:column_names];
			 }
			 */
			
			
			
			NSString *until_date = [oneLine getValueForNamedColumn:@"End Date" headerNames:column_names];
			NSString *appIDString = [oneLine getValueForNamedColumn:@"Apple Identifier" headerNames:column_names];
			NSUInteger appID = [appIDString intValue];
			NSString *vendor_identifier = [oneLine getValueForNamedColumn:@"Vendor Identifier" headerNames:column_names];
			
			if (!vendor_identifier)
			{
				// ITC Format as of Sept 2010
				vendor_identifier = [oneLine getValueForNamedColumn:@"SKU" headerNames:column_names];
			}
			
			NSString *company_name = [oneLine getValueForNamedColumn:@"Artist / Show" headerNames:column_names];
			if (!company_name)
			{
				// ITC Format as of Sept 2010
				company_name = [oneLine getValueForNamedColumn:@"Developer" headerNames:column_names];
			}
			/*
			 if (!company_name)
			 {
			 // ITC Financial Format as of Sept 2010
			 company_name = [oneLine getValueForNamedColumn:@"Artist/Show/Developer/Author" headerNames:column_names];
			 }
			 */
			
			
			NSString *title	= [oneLine getValueForNamedColumn:@"Title / Episode / Season" headerNames:column_names];
			if (!title)
			{
				// ITC Format as of Sept 2010
				title = [oneLine getValueForNamedColumn:@"Title" headerNames:column_names];
			}
			
			
			NSUInteger type_id;
			NSString *typeString = [oneLine getValueForNamedColumn:@"Product Type Identifier" headerNames:column_names];
			NSString *parentIDString = [oneLine getValueForNamedColumn:@"Parent Identifier" headerNames:column_names];
			if ([typeString hasPrefix:@"IA"])
			{
				// in app purchase!
				type_id = 101;
			}
			else
			{
				type_id = [typeString intValue];
			}
			
			NSInteger units = [[oneLine getValueForNamedColumn:@"Units" headerNames:column_names] intValue];
			
			NSString *royaltyPriceString = [oneLine getValueForNamedColumn:@"Royalty Price" headerNames:column_names];
			if (!royaltyPriceString)
			{
				// ITC Format as of Sept 2010
				royaltyPriceString = [oneLine getValueForNamedColumn:@"Developer Proceeds" headerNames:column_names];
			}
			
			/*
			 if (!royaltyPriceString)
			 {
			 // ITC Financial Format as of Sept 2010
			 royaltyPriceString = [oneLine getValueForNamedColumn:@"Partner Share" headerNames:column_names];
			 }
			 */
			double royalty_price = [royaltyPriceString doubleValue];
			
			
			NSString *royalty_currency	= [oneLine getValueForNamedColumn:@"Royalty Currency" headerNames:column_names];
			if (!royalty_currency)
			{
				// ITC Format as of Sept 2010
				// note: weekly reports has "Of"
				royalty_currency = [oneLine getValueForNamedColumn:@"Currency of Proceeds" headerNames:column_names];
			}
			/*
			 if (!royalty_currency)
			 {
			 // ITC Financial Format as of Sept 2010
			 royalty_currency = [oneLine getValueForNamedColumn:@"Partner Share Currency" headerNames:column_names];
			 }			
			 */
			
			double customer_price = [[oneLine getValueForNamedColumn:@"Customer Price" headerNames:column_names] doubleValue];
			NSString *customer_currency	= [oneLine getValueForNamedColumn:@"Customer Currency" headerNames:column_names];
			NSString *country_code	= [oneLine getValueForNamedColumn:@"Country Code" headerNames:column_names];
			/*
			 if (!country_code)
			 {
			 // ITC Financial Format as of Sept 2010
			 country_code = [oneLine getValueForNamedColumn:@"Country Of Sale" headerNames:column_names];
			 }	
			 */
			
			// BOOL financial_report = NO;
			
			// Sept 2010: company name now omitted for IAP
			if ((!from_date)&&(!royalty_currency)&&(!royalty_price)&&(!country_code))
			{
				// probably monthly financial report
				from_date = [oneLine getValueForNamedColumn:@"Start Date" headerNames:column_names];
				
				units = [[oneLine getValueForNamedColumn:@"Quantity" headerNames:column_names] intValue];
				company_name = [oneLine getValueForNamedColumn:@"Artist/Show/Developer" headerNames:column_names];
				
				if (!company_name)
				{	
					// try new format
					company_name = [oneLine getValueForNamedColumn:@"Artist/Show/Developer/Author" headerNames:column_names];
				}
				
				title	= [oneLine getValueForNamedColumn:@"Title" headerNames:column_names];
				royalty_currency	= [oneLine getValueForNamedColumn:@"Partner Share Currency" headerNames:column_names];
				royalty_price = [[oneLine getValueForNamedColumn:@"Partner Share" headerNames:column_names] doubleValue];
				country_code	= [oneLine getValueForNamedColumn:@"Country Of Sale" headerNames:column_names];
				
				
				//financial_report = YES;
				reportType = ReportTypeFinancial;
			}
			
			
			// filter if PARTNERVERSION is active
#ifdef PARTNERVERSION
			NSSet *onlyThese = PARTNERVERSION_FILTER_APPS_SET;
			if (![onlyThese containsObject:appIDString]&&![onlyThese containsObject:parentIDString])
			{
				appID=0; // causes this line to be ignored
			}
#endif
			

			/*
			NSString *salesOrReturn = [oneLine getValueForNamedColumn:@"Promo Code" headerNames:column_names];
			
			if ([salesOrReturn length])
			{
				NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
				for (NSString *oneCol in column_names)
				{
					NSString *v = [oneLine getValueForNamedColumn:oneCol headerNames:column_names];		
					if (v)
					{
						[tmpDict setObject:v forKey:oneCol];
					}
				}
				NSLog(@"Promo!: %@", tmpDict);
				}
			*/
			
			// if all columns have a value then we accept the line
			if (from_date&&until_date&&appID&&vendor_identifier&&title&&type_id&&units&&royalty_currency&&customer_currency&&country_code)
			{
				Country_v1 *saleCountry = [DB countryForCode:country_code];
				
				saleCountry.usedInReport = YES; // makes sure we have an icon
				
				Product_v1 *saleProduct;
				
				if (type_id==1 || type_id==7)
				{
					saleProduct = (Product_v1 *)[DB appForID:appID];
					
					if (!saleProduct)
					{
						saleProduct = (Product_v1 *)[DB insertAppWithTitle:title vendor_identifier:vendor_identifier apple_identifier:appID company_name:company_name];
					}
					
					if (![tmpAppsInReport containsObject:saleProduct])
					{
						[tmpAppsInReport addObject:saleProduct];
					}
				}
				else
				{
					InAppPurchase *iap =[DB iapForID:appID];
					
					App *parentApp = [DB appForVendorID:parentIDString];
					
					if (!iap)
					{
						iap = [DB insertIAPWithTitle:title vendor_identifier:vendor_identifier apple_identifier:appID company_name:company_name parent:parentApp];
					}
					else
					{
						if (!iap.parent)
						{
							iap.parent = parentApp;
							[iap updateInDatabase];
						}
					}
					
					saleProduct = iap;
					
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
				Sale_v1 *newSale = [[Sale_v1 alloc] initWithCountry:saleCountry 
															 report:self 
															product:saleProduct 
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
				[self addSaleToSummaries:newSale];
			}
			else 
			{
				if ([oneLine rangeOfString:@"Total"].location==NSNotFound && [[oneLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]>5)
				{
					
					NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
					for (NSString *oneCol in column_names)
					{
						NSString *v = [oneLine getValueForNamedColumn:oneCol headerNames:column_names];		
						if (v)
						{
							[tmpDict setObject:v forKey:oneCol];
						}
					}
					NSLog(@"Line rejected: %@", tmpDict);
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
- (void)insertIntoDatabase:(sqlite3 *)db 
{
    database = db;
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO report(from_date, until_date, downloaded_date, report_type_id, report_region_id, appgrouping_id) VALUES(?, ?, ?, ?, ?, ?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_text(insert_statement, 1, [[fromDate description]UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement, 2, [[untilDate description]UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement, 3, [[downloadedDate description]UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(insert_statement, 4, reportType);
    sqlite3_bind_int(insert_statement, 5, region);
	
	if (appGrouping)
	{
		sqlite3_bind_int(insert_statement, 6, appGrouping.primaryKey);
	}
	else
	{
		sqlite3_bind_null(insert_statement, 6);
	}
	
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
		for (Sale_v1 *oneSale in sales)
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
}

// only the grouping is to be updated
- (void)updateInDatabase 
{
    // Compile the delete statement if needed.
    if (update_statement == nil) 
	{
        const char *sql = "UPDATE REPORT set appgrouping_id = ? WHERE id = ?";
        if (sqlite3_prepare_v2(database, sql, -1, &update_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_int(update_statement, 1, appGrouping.primaryKey);
    sqlite3_bind_int(update_statement, 2, primaryKey);
    // Execute the query.
    int success = sqlite3_step(update_statement);
    // Reset the statement for future use.
    sqlite3_reset(update_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to update in database with message '%s'.", sqlite3_errmsg(database));
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
		
		Country_v1 *country = [DB countryForCode:cntry_code];
		country.usedInReport = YES; // makes sure we have an icon
		
		// detect region for financial reports
		if ((reportType == ReportTypeFinancial)&&(!region))
		{
			region = [country reportRegion];
		}
		
		Product_v1 *saleProduct = nil;
		
		if (ttype == 1 || ttype == 7)
		{
			
			App *app = [DB appForID:app_id];
			if (app && ![tmpAppsInReport containsObject:app])
			{
				[tmpAppsInReport addObject:app];
			}
			
			saleProduct = app;
		}
		else if (ttype == 101)
		{
			saleProduct = [DB iapForID:app_id];
		}
		
		if (saleProduct)
		{
			
			Sale_v1 *tmpSale = [[Sale_v1 alloc] initWithCountry:country report:self product:saleProduct units:units royaltyPrice:royalty_price royaltyCurrency:royalty_currency customerPrice:customer_price customerCurrency:customer_currency transactionType:ttype];
			
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

- (NSString *)monthForMonthlyReports:(BOOL)shorter
{
	NSDate *tmpDate = [self dateInMiddleOfReport];
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	if (shorter)
	{
		[df setDateFormat:@"MMM YYYY"];
	}
	else
	{
		[df setDateFormat:@"MMMM YYYY"];
	}
	
	
	return [df stringFromDate:tmpDate];
}

- (NSString *)shortNameForRegion:(ReportRegion)reportRegion
{
	switch (reportRegion) 
	{
		case ReportRegionUK:
			return @"UK";
		case ReportRegionUSA:
			return @"US";
		case ReportRegionEurope:
			return @"EU";
		case ReportRegionJapan:
			return @"JP";
		case ReportRegionCanada:
			return @"CA";
		case ReportRegionAustralia:
			return @"AU";
		case ReportRegionRestOfWorld:
			return @"WW";
		default:
			return @"??";
	}
}

- (NSString *)descriptionFinancialShort
{
	NSString *region_name = [self shortNameForRegion:region];
	
	NSDate *tmpDate = [self dateInMiddleOfReport];
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateFormat:@"MM/YYYY"];
	
	NSString *monthString = [df stringFromDate:tmpDate];
	return [NSString stringWithFormat:@"%@ %@", region_name, monthString];
}

- (NSString *)listDescriptionShorter:(BOOL)shorter
{
	switch (reportType) {
		case ReportTypeDay:
		{
			NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
			[formatter setDateStyle:shorter?NSDateFormatterMediumStyle:NSDateFormatterLongStyle];
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
			return [NSString stringWithFormat:@"%@ to %@",[formatter stringFromDate:fromDate], [formatter stringFromDate:untilDate]];
			break;
		}
		case ReportTypeFree:
		{
			return [self monthForMonthlyReports:shorter];
			break;
		}
		case ReportTypeFinancial:
		{
			if (shorter)
			{
				return [self descriptionFinancialShort];
			}
			
			NSString *region_name;
			
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
			
			return [NSString stringWithFormat:@"%@ %@", [self monthForMonthlyReports:shorter], region_name];
			break;
		}
			
			
		default:
			return [fromDate description];
			break;
	}
	
}

- (NSString *)description
{
	return [self listDescriptionShorter:NO];
}

- (NSUInteger) day
{
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *comps = [gregorian components:NSDayCalendarUnit fromDate:self.fromDate];
	return comps.day;
}

- (NSString *) reconstructedFileName
{
	
	switch (reportType) 
	{
		case ReportTypeDay:
		{
			NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
			[df setDateFormat:@"yyyyMMdd"];
			return [NSString stringWithFormat:@"S_D_%@.txt", [df stringFromDate:self.fromDate]];
		}
		case ReportTypeWeek:
		{
			NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
			[df setDateFormat:@"yyyyMMdd"];
			return [NSString stringWithFormat:@"S_W_%@.txt", [df stringFromDate:self.fromDate]];
		}					
		case ReportTypeFinancial:
		{
			NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
			[df setDateFormat:@"MMyy"];
			return [NSString stringWithFormat:@"%@_%@.txt", [df stringFromDate:[self dateInMiddleOfReport]], [self shortNameForRegion:region]];
		}					
			
		case ReportTypeFree:
		{
			NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
			[df setDateFormat:@"yyyyMMdd"];
			return [NSString stringWithFormat:@"S_M_%@.txt", [df stringFromDate:self.fromDate]];
		}
		default:
			// need to set a case for different types, because otherwise Analyze complains
			return [NSString stringWithFormat:@"UnknownID%d", primaryKey];
			
			break;
	}
}


- (NSString *) reconstructText
{
	[self hydrate];  // to load all infos necessary
	
	NSMutableString *ret = [[NSMutableString alloc] init];
	
	[ret appendString:@"Provider	Provider Country	Vendor Identifier	UPC	ISRC	Artist / Show	Title / Episode / Season	Label/Studio/Network	Product Type Identifier	Units	Royalty Price	Begin Date	End Date	Customer Currency	Country Code	Royalty Currency	Preorder	Season Pass	ISAN	Apple Identifier	Customer Price	CMA	Asset/Content Flavor	Vendor Offer Code	Grid	Promo Code	Parent Identifier\r\n"];
	
	NSEnumerator *enu = [sales objectEnumerator];
	Sale_v1 *oneSale;
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"MM/dd/yyyy"];
	//[df setDateStyle:NSDateFormatterShortStyle];
	
	while ((oneSale = [enu nextObject]))
	{
		// one report line
		
		NSString *typeString = (oneSale.transactionType==101)?@"IA1":[NSString stringWithFormat:@"%d",(int)oneSale.transactionType];
		NSString *parentID;
		
		if ([oneSale.product isKindOfClass:[InAppPurchase class]])
		{
			parentID = ((InAppPurchase *)oneSale.product).parent.vendor_identifier;
		}
		else 
		{
			parentID = @"";
		}
		
		
		[ret appendFormat:@"APPLE\tUS\t%@\t\t\t%@\t%@\t\t%@\t%d\t%.2f\t%@\t%@\t%@\t%@\t%@\t\t\t\t%d\t%.2f\t\t\t\t\t\t%@\r\n", oneSale.product.vendor_identifier, oneSale.product.company_name, oneSale.product.title, 
		 typeString, oneSale.unitsSold, oneSale.royaltyPrice, [df stringFromDate:fromDate], [df stringFromDate:untilDate], oneSale.customerCurrency, oneSale.country.iso2,
		 oneSale.royaltyCurrency, oneSale.product.apple_identifier, oneSale.customerPrice, parentID];
	}
	
	[df release];
	
	NSString *retStatic = [NSString stringWithString:ret];
	[ret release];
	
	return retStatic;
}

- (NSString *)stubAsString
{
	return [NSString stringWithFormat:@"%d/%.0f/%.0f/%.0f/%d/%d/%d", primaryKey, 
			[fromDate timeIntervalSinceReferenceDate], 
			[untilDate timeIntervalSinceReferenceDate],
			[downloadedDate timeIntervalSinceReferenceDate],
			region, reportType, appGrouping.primaryKey];
}


#pragma mark Summing

- (void) resetSummaries
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
}

- (void) addSaleToSummaries:(Sale_v1 *)oneSale
{
	// get or create app 
	NSNumber *productKey = [oneSale.product identifierAsNumber];
	NSMutableDictionary *tmpSummaries = [summariesByApp objectForKey:productKey];
	
	if (!tmpSummaries)
	{  // not yet a summary array for this app
		tmpSummaries = [[NSMutableDictionary alloc] init];
		[summariesByApp setObject:tmpSummaries forKey:productKey];
		[tmpSummaries release];
	}
	
	// in the summary array we add the current sale's data
	
	CountrySummary *tmpSummary = [tmpSummaries objectForKey:oneSale.country.iso2];  // sum per country
	//CountrySummary *totalSummary = [tmpSummaries objectForKey:@"___"]; // sum total
	
	
	if (!tmpSummary)
	{
		tmpSummary = [CountrySummary blankSummary];
		tmpSummary.country = oneSale.country;
		[tmpSummaries setObject:tmpSummary forKey:oneSale.country.iso2];  // just an array, no key for adding
	}
	
	/*
	 if (!totalSummary)
	 {
	 totalSummary = [CountrySummary blankSummary];
	 totalSummary.royaltyCurrency = [[YahooFinance sharedInstance] mainCurrency];
	 
	 [tmpSummaries setObject:totalSummary forKey:@"___"];  // just an array, no key for adding
	 }
	 */
	
	switch (oneSale.transactionType) {
		case TransactionTypeSale:
		case TransactionTypeIAP:
		{
			if (oneSale.unitsSold>0)
			{
				tmpSummary.sumSales+=oneSale.unitsSold;
				tmpSummary.sumRoyalites+= oneSale.royaltyPrice*oneSale.unitsSold;
				tmpSummary.royaltyCurrency = oneSale.royaltyCurrency;
				
				//totalSummary.sumSales+=oneSale.unitsSold;
				//totalSummary.sumRoyalites+= [[YahooFinance sharedInstance] convertToMainCurrencyAmount:oneSale.royaltyPrice*oneSale.unitsSold fromCurrency:oneSale.royaltyCurrency];
				
				if (oneSale.royaltyPrice)
				{
					sumUnitsSold+=oneSale.unitsSold;
				}
				else
				{
					sumUnitsFree+=oneSale.unitsSold;
				}
				
			}
			else
			{
				tmpSummary.sumRefunds +=oneSale.unitsSold;
				//totalSummary.sumRefunds +=oneSale.unitsSold;
				
				
				sumUnitsRefunded +=oneSale.unitsSold;
			}
			
			// sumRoyaltiesEarned get's calculated when needed
			
			break;
		}
		case TransactionTypeFreeUpdate:
		{
			tmpSummary.sumUpdates += oneSale.unitsSold;
			//totalSummary.sumUpdates += oneSale.unitsSold;
			sumUnitsUpdated += oneSale.unitsSold;
		}
			
		default:
			break;
	}
}


- (void) makeSummariesFromSales
{
	[self resetSummaries];
	
	// go through all sales
	
	for (Sale_v1 *oneSale in sales)
	{
		[self addSaleToSummaries:oneSale];
	}
}



#pragma mark Sums
- (NSInteger) sumUnitsForProduct:(Product_v1 *)product transactionType:(TransactionType)ttype
{
	NSArray *tmpArray;
	
	if (product)
	{
		tmpArray = [self.salesByApp objectForKey:[product identifierAsNumber]];
	}
	else
	{
		tmpArray = sales;
	}
	
	NSInteger ret = 0;
	
	if (tmpArray)
	{
		NSEnumerator *en = [tmpArray objectEnumerator];
		Sale_v1 *aSale;
		
		while ((aSale = [en nextObject]))
		{
			if ((ttype==aSale.transactionType)&&(aSale.unitsSold>0))
			{
				ret += aSale.unitsSold;
			}
		}
	}
	
	return ret;
}

- (NSInteger) sumRefundsForProduct:(Product_v1 *)product
{
	NSArray *tmpArray;
	TransactionType ttype = 0;
	
	if ([product isKindOfClass:[App class]])
	{
		ttype = TransactionTypeSale;
	}
	else if ([product isKindOfClass:[InAppPurchase class]])
	{
		ttype = TransactionTypeIAP;
	}
	
	if (product)
	{
		tmpArray = [self.salesByApp objectForKey:[product identifierAsNumber]];
	}
	else
	{
		tmpArray = sales;
	}
	
	NSInteger ret = 0;
	
	if (tmpArray)
	{
		NSEnumerator *en = [tmpArray objectEnumerator];
		Sale_v1 *aSale;
		
		while ((aSale = [en nextObject]))
		{
			if ((!product)||(product&&(ttype==aSale.transactionType)))
			{
				if (aSale.unitsSold<0)
				{
					ret += aSale.unitsSold;
				}
			}
		}
	}
	
	return ret;
}

- (double) sumRoyaltiesForProduct:(Product_v1 *)product transactionType:(TransactionType)ttype
{
	NSArray *tmpArray;
	
	if (product)
	{
		tmpArray = [self.salesByApp objectForKey:[product identifierAsNumber]];
	}
	else
	{
		tmpArray = self.sales;
	}
	
	double ret = 0;
	
	if (tmpArray)
	{
		
		NSEnumerator *en = [tmpArray objectEnumerator];
		Sale_v1 *aSale;
		
		while ((aSale = [en nextObject]))
		{
			if ((ttype==aSale.transactionType))
			{
				ret += [[YahooFinance sharedInstance] convertToEuro:(aSale.royaltyPrice * aSale.unitsSold) fromCurrency:aSale.royaltyCurrency]; 
			}
		}
	}
	
	return ret;
}



- (double) sumRoyaltiesForInAppPurchasesOfApp:(App *)app
{
	NSArray *iaps = [app inAppPurchases];
	double ret = 0;
	
	for (InAppPurchase *iap in iaps)
	{
		ret += [self sumRoyaltiesForProduct:iap transactionType:TransactionTypeIAP];
	}
	return ret;
}

- (NSInteger) sumUnitsForInAppPurchasesOfApp:(App *)app
{
	NSArray *iaps = [app inAppPurchases];
	NSInteger ret = 0;
	
	for (InAppPurchase *iap in iaps)
	{
		ret += [self sumUnitsForProduct:iap transactionType:TransactionTypeIAP];
	}
	return ret;
}

- (NSInteger) sumRefundsForInAppPurchasesOfApp:(App *)app
{
	NSArray *iaps = [app inAppPurchases];
	NSInteger ret = 0;
	
	for (InAppPurchase *iap in iaps)
	{
		ret += [self sumRefundsForProduct:iap];
	}
	return ret;
}


- (double) sumRoyaltiesForAppId:(NSUInteger)app_id inCurrency:(NSString *)curCode
{
	NSMutableArray *tmpArray = [self.salesByApp objectForKey:[NSNumber numberWithInt:app_id]];
	double ret = 0;
	
	if (tmpArray)
	{
		
		NSEnumerator *en = [tmpArray objectEnumerator];
		Sale_v1 *aSale;
		
		while ((aSale = [en nextObject]))
		{
			if (aSale.transactionType==TransactionTypeSale)
			{
				ret += [[YahooFinance sharedInstance] convertToCurrency:curCode amount:(aSale.royaltyPrice * aSale.unitsSold) fromCurrency:aSale.royaltyCurrency];
			}
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
	
	for (NSNumber *oneKey in [self.salesByApp allKeys])
	{
		ret += [self sumRoyaltiesForAppId:[oneKey intValue] inCurrency:@"EUR"];   // internally all is Euro
	}
	
	// cache it
	sumRoyaltiesEarned = ret;
	return ret;
}

/*
 - (NSInteger) sumRefundsForAppId:(NSUInteger)app_id
 {
 NSMutableArray *tmpArray = [salesByApp objectForKey:[NSNumber numberWithInt:app_id]];
 NSInteger ret = 0;
 
 if (tmpArray)
 {
 NSEnumerator *en = [tmpArray objectEnumerator];
 Sale *aSale;
 
 while ((aSale = [en nextObject]))
 {
 if ((aSale.transactionType==TransactionTypeSale)&&(aSale.unitsSold<0))
 {
 ret += aSale.unitsSold;
 }
 }
 }
 
 return ret;
 }
 */

- (CountrySummary *)summaryForIAPofApp:(App *)app
{
	CountrySummary *tmpSummary = [CountrySummary blankSummary];
	
	NSArray *iaps = [DB iapsForApp:app];
	
	for (InAppPurchase *oneIAP in iaps)
	{
		CountrySummary *oneSummary = [[self.summariesByApp objectForKey:[oneIAP identifierAsNumber]] objectForKey:@"___"];
		
		// copy main currency from first one
		if (!tmpSummary.royaltyCurrency)
		{
			tmpSummary.royaltyCurrency = oneSummary.royaltyCurrency;
		}
		
		tmpSummary.sumRefunds += oneSummary.sumRefunds;
		tmpSummary.sumSales += oneSummary.sumSales;
		tmpSummary.sumUpdates += oneSummary.sumUpdates;
		tmpSummary.sumRoyalites += oneSummary.sumRoyalites;
	}
	
	
	return tmpSummary;
}


#pragma mark Report Displaying

- (NSArray *)sectionsForReportDisplay
{
	NSMutableArray *sectionArray = [NSMutableArray array];
	
	
	// each section is a dictionary
	
	// first section is trans total
	
	CountrySummary *grandTotalSummary = [CountrySummary blankSummary];
	{
		NSMutableDictionary *sectionDict = [NSMutableDictionary dictionary];
		[sectionDict setObject:@"Grand Total" forKey:@"Title"];
		[sectionDict setObject:[NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObject:grandTotalSummary forKey:@"Summary"]] forKey:@"Rows"];
		
		[sectionArray addObject:sectionDict];
		
	}
	
	// sections 1..n are the apps for this appgrouping sorted by income
	
	NSArray *sortedApps = [DB appsSortedBySalesWithGrouping:self.appGrouping];
	
	// loop through apps and add 1 row for regular or 3 rows for IAP-apps
	for (App* oneApp in sortedApps)
	{
		NSMutableDictionary *sectionDict = [NSMutableDictionary dictionary];
		[sectionDict setObject:oneApp.title forKey:@"Title"];
		[sectionDict setObject:oneApp forKey:@"App"];
		[sectionArray addObject:sectionDict];
		
		NSMutableArray *rowArray = [NSMutableArray array];
		[sectionDict setObject:rowArray forKey:@"Rows"];
		
		
		NSArray *oneAppIAPs = [oneApp inAppPurchases];
		if (oneAppIAPs)
		{
			// need to sum IAPs
			
			CountrySummary *appSummary = [[summariesByApp objectForKey:[oneApp identifierAsNumber]] objectForKey:@"___"];
			CountrySummary *allIAPSummary = [self summaryForIAPofApp:oneApp];
			CountrySummary *totalSummary = [appSummary summaryByAddingSummary:allIAPSummary];
			
			if (!totalSummary.royaltyCurrency)
			{
				totalSummary.royaltyCurrency = [[YahooFinance sharedInstance] mainCurrency];
			}
			// 3 rows
			
			// first: total sales + IAPs
			[rowArray addObject:totalSummary];
			
			[grandTotalSummary addSummary:totalSummary];
			
			// second: total sales
			[rowArray addObject:appSummary];
			
			
			// third: IAPs
			[rowArray addObject:allIAPSummary];
			
		}
		else
		{
			// 1 row
			NSDictionary *summariesForApp = [summariesByApp objectForKey:[oneApp identifierAsNumber]];
			CountrySummary *appSummary = [summariesForApp objectForKey:@"___"];
			[grandTotalSummary addSummary:appSummary];
			
			
			NSMutableDictionary *rowDict = [NSMutableDictionary dictionary];
			[rowDict setObject:appSummary forKey:@"Summary"];
			
			NSArray *sortedKeys = [summariesForApp keysSortedByValueUsingSelector:@selector(compareBySales:)];
			
			NSMutableDictionary *detailSectionDict = [NSMutableDictionary dictionary];
			NSMutableArray *detailRowsArray = [NSMutableArray array];
			
			
			for (NSString *oneKey in sortedKeys)
			{
				CountrySummary *oneSummary = [summariesForApp objectForKey:oneKey];
				[detailRowsArray addObject:oneSummary];
			}
			
			[detailSectionDict setObject:detailRowsArray forKey:@"Rows"];
			
			[rowDict setObject:detailSectionDict forKey:@"Detail"];
			[rowArray addObject:rowDict];
		}
		
	}
	
	return [NSArray arrayWithArray:sectionArray];
}

#pragma mark Properties
// Accessors implemented below. All the "get" accessors simply return the value directly, with no additional
// logic or steps for synchronization. The "set" accessors attempt to verify that the new value is definitely
// different from the old value, to minimize the amount of work done. Any "set" which actually results in changing
// data will mark the object as "dirty" - i.e., possessing data that has not been written to the database.
// All the "set" accessors copy data, rather than retain it. This is common for value objects - strings, numbers, 
// dates, data buffers, etc. This ensures that subsequent changes to either the original or the copy don't violate 
// the encapsulation of the owning object.

- (NSMutableDictionary *)salesByApp
{
	if (!salesByApp)
	{
		[self hydrate];
	}
	
	return salesByApp;
}

- (NSMutableArray *)sales
{
	if (!sales)
	{
		[self hydrate];
	}
	
	return sales;
}

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
- (NSComparisonResult)compareByReportDateDesc:(Report_v1 *)otherObject
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

/*
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
 */

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
