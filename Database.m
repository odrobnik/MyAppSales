//
//  Database.m
//  ASiST
//
//  Created by Oliver on 28.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "Database.h"
#import "App.h"
#import "Report.h"
#import "Country.h"

#import "NSString+Helpers.h"
#import "ZipArchive.h"



// private methods
@interface Database ()
- (void) connect;
- (void) createEditableCopyOfDatabaseIfNeeded;
- (void) updateSchemaIfNeeded;
- (void)initializeDatabase;

- (void)calcAvgRoyaltiesForApps;
- (void)getTotals;

- (void) sendNewAppNotification:(App *)app;
- (void) sendNewReportNotification:(Report *)report;
- (void) setStatus:(NSString *)message;



@property (nonatomic, retain, readwrite) NSMutableDictionary *apps;
@property (nonatomic, retain, readwrite) NSMutableDictionary *reports;
@property (nonatomic, retain, readwrite) NSMutableDictionary *countries;

@property (nonatomic, retain, readwrite) NSMutableDictionary *reportsByReportType;

@property (nonatomic, retain) NSMutableArray *dataToImport;

@end

static Database *_sharedInstance;

@implementation Database

@synthesize database;
@synthesize apps, reports, countries, languages;
@synthesize reportsByReportType;
@synthesize dataToImport;

+ (Database *) sharedInstance
{
	if (!_sharedInstance)
	{
		_sharedInstance = [Database alloc];
		[_sharedInstance init];   // prevents endless loop, report is using sharedInstance inside init
	}
	return _sharedInstance;
}

- (id) init
{
	if (self = [super init])
	{
		newReportsByType = [[NSMutableDictionary alloc] init];
		
		// connect with database
		[self createEditableCopyOfDatabaseIfNeeded];
		[self connect];
		[self updateSchemaIfNeeded];
		[self initializeDatabase];
		
		[self calcAvgRoyaltiesForApps];
		[self getTotals];
		
		// subscribe to change of exchange rates
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRatesChanged:) name:@"ExchangeRatesChanged" object:nil];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	

	[dataToImport release];
	
	// release indexes
	[reportsByReportType release];
	[newReportsByType release];
	
	// release tables
	[apps release];
	[reports release];
	[countries release];
	[languages release];
	
	[super dealloc];
}

#pragma mark Connection
// Creates a writable copy of the bundled default database in the application Documents directory.
- (void)createEditableCopyOfDatabaseIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"apps.db"];
	//NSLog(@"DB: %@", writableDBPath);
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"apps.db"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}

- (void) connect
{
	// The database is stored in the documents directory 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"apps.db"];
	
	NSLog(@"Connected to DB %@", path);
	
	if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) 
	{
		// all is well
	}
	else
	{
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(database);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
        // Additional error handling, as appropriate...
    }	
}

- (void) disconnect
{
	sqlite3_close(database);
}

#pragma mark Schema Updating

- (void)executeSchemaUpdate:(NSString *)scriptName
{
	// scripts are in the app bundle
	NSString *scriptPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:scriptName];
	
	NSString *script = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:NULL];
	
	char *errmsg;
	
	if (sqlite3_exec(database, [script UTF8String], NULL, NULL, &errmsg)!=SQLITE_OK)
	{
 		sqlite3_close(database);
        NSAssert1(0, @"Failed to execute update script with message '%s'.", errmsg);
	}
}


- (void)updateSchemaIfNeeded
{
	int schema_version = 0;
	
	char *sql = "SELECT schema_version FROM meta";
	sqlite3_stmt *statement;
	// Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.        
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
	{
		if (sqlite3_step(statement) == SQLITE_ROW) 
		{
			// The second parameter indicates the column index into the result set.
			schema_version = sqlite3_column_int(statement, 0);
		}
		
	}
	else
	{
		// no schema version, version = 1
		schema_version = 0;
	}
	sqlite3_finalize(statement);

	
	// execute all updates incrementially which are necessary 
	switch (schema_version) {
		case 0:
			[self executeSchemaUpdate:@"update_0_to_1.sql"];
		case 1:
			[self executeSchemaUpdate:@"update_1_to_2.sql"];
		case 2:
			[self executeSchemaUpdate:@"update_2_to_3.sql"];
		case 3:
			[self executeSchemaUpdate:@"update_3_to_4.sql"];
		default:
			break;
	}
}

#pragma mark Loading of Tables
// Load all apps and reports
- (void)initializeDatabase 
{
	char *sql;
	sqlite3_stmt *statement;
	
	// get current system language
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *appleLanguages = [userDefaults objectForKey:@"AppleLanguages"];
	NSString *currentLanguage = [appleLanguages objectAtIndex:0];
	
	
	NSLocale *loc = [[[NSLocale alloc] initWithLocaleIdentifier:currentLanguage] autorelease];
	
	
	// set language default to current system language if not set
	if  (![[NSUserDefaults standardUserDefaults] objectForKey:@"ReviewTranslation"])
	{
		[[NSUserDefaults standardUserDefaults] setObject:currentLanguage forKey:@"ReviewTranslation"];
	}
	 
	
	// load all countries
	self.countries = [NSMutableDictionary dictionary];  // does not need to be mutable
	//self.languages = [NSMutableDictionary dictionary];  // does not need to be mutable
	
	// also load the legal language codes into temp array for later sorting
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	[tmpDict setObject:@" Don't translate" forKey:@" "];  // leading space orders it first in list
	
	sql = "SELECT iso3, language from country";
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	
	while (sqlite3_step(statement) == SQLITE_ROW) 
	{
		NSString *cntry = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
		Country *tmpCountry = [[Country alloc] initWithISO3:cntry database:database];
		[countries setObject:tmpCountry forKey:tmpCountry.iso2];
		[tmpCountry release];

		// get language
		char *lang_code;
		if (lang_code = (char *)sqlite3_column_text(statement, 1))
		{
			NSString *language_code = [NSString stringWithUTF8String:lang_code];
			NSString *language_name = [loc displayNameForKey:NSLocaleLanguageCode value:language_code];
			
			if (language_code&&language_name)
			{
				[tmpDict setObject:language_name forKey:language_code];
			}
		}
	} 

	// Finalize the statement, no reuse.
	sqlite3_finalize(statement);
	
	languages = [tmpDict retain];
	
	// Load all apps
    self.apps = [NSMutableDictionary dictionary];
	sql = "SELECT id FROM app";

	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
	{
		// We "step" through the results - once for each row.
		while (sqlite3_step(statement) == SQLITE_ROW) 
		{
			// The second parameter indicates the column index into the result set.
			int primaryKey = sqlite3_column_int(statement, 0);
			
			// We avoid the alloc-init-autorelease pattern here because we are in a tight loop and
			// autorelease is slightly more expensive than release. This design choice has nothing to do with
			// actual memory management - at the end of this block of code, all the book objects allocated
			// here will be in memory regardless of whether we use autorelease or release, because they are
			// retained by the books array.
			App *app = [[App alloc] initWithPrimaryKey:primaryKey database:database];
			
			[apps setObject:app forKey:[NSNumber numberWithInt:primaryKey]];
			[app release];
		}
	}
	// "Finalize" the statement - releases the resources associated with the statement.
	sqlite3_finalize(statement); 
	
	
	// Load all reports
	
    self.reports = [NSMutableDictionary dictionary];
	self.reportsByReportType = [NSMutableDictionary dictionary];
	sql = "SELECT id FROM report order by from_date";
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
	{
		// We "step" through the results - once for each row.
		while (sqlite3_step(statement) == SQLITE_ROW) 
		{
			// The second parameter indicates the column index into the result set.
			int primaryKey = sqlite3_column_int(statement, 0);
			
			// We avoid the alloc-init-autorelease pattern here because we are in a tight loop and
			// autorelease is slightly more expensive than release. This design choice has nothing to do with
			// actual memory management - at the end of this block of code, all the book objects allocated
			// here will be in memory regardless of whether we use autorelease or release, because they are
			// retained by the books array.
			Report *report = [[Report alloc] initWithPrimaryKey:primaryKey database:database];
			
			[reports setObject:report forKey:[NSNumber numberWithInt:primaryKey]];
			
			// also add to the indexes
			
			NSNumber *reportTypeKey = [NSNumber numberWithInt:(int)report.reportType];
			
			NSMutableArray *arrayForThisType = [reportsByReportType objectForKey:reportTypeKey];
			
			if (!arrayForThisType)
			{
				// this is the first report of this type, create corresponding array
				arrayForThisType = [NSMutableArray array];
				[reportsByReportType setObject:arrayForThisType forKey:reportTypeKey];
			}
			
			[arrayForThisType addObject:report];
			[report release];
		}
	}
	// "Finalize" the statement - releases the resources associated with the statement.
	sqlite3_finalize(statement);
}

#pragma mark Accessing Database
- (NSArray *) sortedReportsOfType:(ReportType)type
{
	NSNumber *reportTypeKey = [NSNumber numberWithInt:type];
	NSMutableArray *arrayForThisType = [reportsByReportType objectForKey:reportTypeKey];
	
	if (!arrayForThisType) return nil;  // invalid type
	
	NSSortDescriptor *dateDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"fromDate" ascending:NO] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
	NSArray *sortedArray = [arrayForThisType sortedArrayUsingDescriptors:sortDescriptors];
	
	return [NSArray  arrayWithArray:sortedArray];  // non-mutable, autoreleased
}

- (Report *) reportNewerThan:(Report *)aReport
{
	NSArray *sortedReports = [self sortedReportsOfType:aReport.reportType];
	
	NSUInteger currentIdx = [sortedReports indexOfObject:aReport];
	
	if (currentIdx>0)
	{
		currentIdx--;
	}
	
	return [sortedReports objectAtIndex:currentIdx];
}

- (Report *) reportOlderThan:(Report *)aReport
{
	NSArray *sortedReports = [self sortedReportsOfType:aReport.reportType];
	
	NSUInteger currentIdx = [sortedReports indexOfObject:aReport];
	
	if (currentIdx<([sortedReports count]-1))
	{
		currentIdx++;
	}
	
	return [sortedReports objectAtIndex:currentIdx];
}


- (Report *) latestReportOfType:(ReportType)type
{
	NSArray *tmpArray = [self sortedReportsOfType:type];
	
	if (!tmpArray||![tmpArray count]) return nil;
	
	return [tmpArray objectAtIndex:0];
}

- (App *) appForID:(NSUInteger)appID
{
	NSNumber *app_key = [NSNumber numberWithInt:appID];
	return [apps objectForKey:app_key];
}

- (Report *) reportForID:(NSUInteger)reportID
{
	NSNumber *report_key = [NSNumber numberWithInt:reportID];
	return [reports objectForKey:report_key];
}


- (NSArray *) allReports
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	NSArray *dayArray = [reportsByReportType objectForKey:[NSNumber numberWithInt:ReportTypeDay]];
	NSArray *weekArray = [reportsByReportType objectForKey:[NSNumber numberWithInt:ReportTypeWeek]];
	NSArray *financialArray = [reportsByReportType objectForKey:[NSNumber numberWithInt:ReportTypeFinancial]];
	NSArray *freeArray = [reportsByReportType objectForKey:[NSNumber numberWithInt:ReportTypeFree]];
	
	[tmpArray addObjectsFromArray:dayArray];
	[tmpArray addObjectsFromArray:weekArray];	
	[tmpArray addObjectsFromArray:financialArray];
	[tmpArray addObjectsFromArray:freeArray];
	
	return [NSArray arrayWithArray:tmpArray];  // non-mutable, autoreleased
}

- (Country *) countryForName:(NSString *)countryName
{
	NSArray *allKeys = [countries allKeys];
	
	for (NSString *oneKey in allKeys)
	{
		Country *oneCountry = [countries objectForKey:oneKey];
		
		if ([[oneCountry.name lowercaseString] isEqualToString:[countryName lowercaseString]])
		{
			return oneCountry;
		}
		
	}
	
	return nil;
}


- (Country *) countryForCode:(NSString *)code
{
	if ([code length]==2)
	{
		// iso2 code
		return [countries objectForKey:code];
	}
	else
	{
		// most likely this is a country name
		
		if ([code isEqualToString:@"USA"])
		{
			return [self countryForName:@"United States"];
		}
		else 
		{
			return [self countryForName:code];
		}
	}

}

/*
- (NSArray *) languagesSorted
{
	NSArray *sortedKeys = [languages keysSortedByValueUsingSelector:@selector(compare:)];
	NSArray *sortedObjects = [languages objectsForKeys:sortedKeys notFoundMarker:@"Dummy"];
	
	return sortedObjects;
}
*/

- (NSUInteger) countOfApps
{
	return [apps count];
}

- (NSUInteger) countOfReportsForType:(ReportType)type
{
	NSNumber *reportTypeKey = [NSNumber numberWithInt:(int)type];
	NSArray *arrayForThisType = [reportsByReportType objectForKey:reportTypeKey];
	
	if (arrayForThisType)
	{
		return [arrayForThisType count];
	}
	else
	{
		return 0;
	}
}

- (NSUInteger) countOfNewReportsForType:(NSUInteger)reportType
{
	NSNumber *typeKey = [NSNumber numberWithInt:reportType];
	return [[newReportsByType objectForKey:typeKey] intValue];
}

- (NSArray *) appKeysSortedBySales
{
	NSArray *sortedKeys = [apps keysSortedByValueUsingSelector:@selector(compareBySales:)];
	return sortedKeys;
}

- (NSArray *) appsSortedBySales
{
	NSArray *sortedKeys = [self appKeysSortedBySales];
	NSEnumerator *enu = [sortedKeys objectEnumerator];
	NSNumber *oneKey;
	NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:[sortedKeys count]];
	
	
	while (oneKey = [enu nextObject]) {
		App *oneApp = [apps objectForKey:oneKey];
		[tmpArray addObject:oneApp];
	}
	
	NSArray *ret = [NSArray arrayWithArray:tmpArray];
	[tmpArray release];
	
	return ret;
}

- (BOOL) hasNewReportsOfType:(ReportType)type
{
	NSNumber *typeKey = [NSNumber numberWithInt:(int)type];
	return (BOOL) [[newReportsByType objectForKey:typeKey] intValue];
}


#pragma mark Inserting

- (App *) insertAppWithTitle:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name;
{
	NSLog(@"Added app: %@", title);
	// this also adds it to the database
	App *tmpApp = [[App alloc] initWithTitle:title vendor_identifier:vendor_identifier apple_identifier:apple_identifier company_name:company_name database:database];
	
	[apps setObject:tmpApp forKey:[NSNumber numberWithInt:apple_identifier]];
	
	newApps ++;
	[self sendNewAppNotification:tmpApp];
	
	return [tmpApp autorelease];
}

- (Report *) insertReportWithType:(ReportType)type from_date:(NSDate *)from_date until_date:(NSDate *)until_date downloaded_date:(NSDate *)downloaded_date region:(ReportRegion)region
{
	if ((!from_date)||(!until_date)) return nil;
	
	// this also adds it to the database
	Report *tmpReport = [[Report alloc] initWithType:type from_date:from_date until_date:until_date downloaded_date:downloaded_date region:region database:database];
	
	[reports setObject:tmpReport forKey:[NSNumber numberWithInt:tmpReport.primaryKey]];
	
	// also add it to the type index
	NSNumber *reportTypeKey = [NSNumber numberWithInt:(int)tmpReport.reportType];
	NSMutableArray *arrayForThisType = [reportsByReportType objectForKey:reportTypeKey];
	
	if (!arrayForThisType)
	{
		// this is the first report of this type, create corresponding array
		arrayForThisType = [NSMutableArray array];
		[reportsByReportType setObject:arrayForThisType forKey:reportTypeKey];
	}
	
	[arrayForThisType addObject:tmpReport];
	
	newReports ++;

	[self calcAvgRoyaltiesForApps];
	[self sendNewReportNotification:tmpReport];
	
	// local number of daily/weekly new Reports tracking
	NSNumber *typeKey = [NSNumber numberWithInt:tmpReport.reportType];
	
	[newReportsByType setObject:[NSNumber numberWithInt:1 + [[newReportsByType objectForKey:typeKey] intValue]] forKey:typeKey];

	return [tmpReport autorelease];
}


// monthly free reports dont have beginning and end dates, thus they need to be supplied
- (Report *) insertMonthlyFreeReportFromFromDict:(NSDictionary *)dict
{
	NSDate *fromDate = [dict objectForKey:@"FromDate"];
	NSDate *untilDate = [dict objectForKey:@"UntilDate"];
	NSString *string = [dict objectForKey:@"Text"];
	
	//NSLog(@"%@", string);
	NSUInteger report_id=0;
	Report *insertedReport = nil;
	
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
		
		// free:headers Developer	Title/Application	Product Type Identifier	Units	Partner Share	Partner Share Currency	Customer Price	Customer Currency	Country Code	Apple Identifier	Vendor Identifier
		
		
		if (fromDate&&untilDate&&appID&&vendor_identifier&&company_name&&title&&type_id&&units&&royalty_currency&&customer_currency&&country_code)
		{
			if (!report_id)
			{  
				
				//if ([self reportIDForDateString:until_date type:ReportTypeFree region:ReportRegionUnknown]) return nil;
					
				insertedReport = [self insertReportWithType:ReportTypeFree from_date:fromDate until_date:untilDate downloaded_date:[NSDate date] region:ReportRegionUnknown];
				report_id= insertedReport.primaryKey;
				
				if (!insertedReport)
				{
					// if we could not insert it, it's probably already in DB
					return nil;
				}
			}
			
			if (insertedReport)
			{
				if (![DB appForID:appID])
				{
					
					[DB insertAppWithTitle:title vendor_identifier:vendor_identifier apple_identifier:appID company_name:company_name];
					
				}
				
				[insertedReport insertSaleForAppID:appID type_id:type_id units:units royalty_price:royalty_price royalty_currency:royalty_currency customer_price:customer_price customer_currency:customer_currency country_code:country_code];
			}
			
		}
		else
		{
			// lines that don't match the headers, most likey empty lines after the report
		} 
		
	//	prev_until_date = until_date;
	}
	
	if (!insertedReport)
	{
		//try again, maybe it's empty and then this prevents constant retrying
		insertedReport = [self insertReportWithType:ReportTypeFree from_date:fromDate until_date:untilDate downloaded_date:[NSDate date] region:ReportRegionUnknown];
	}
	//[insertedReport makeSummariesFromSales];
	return insertedReport;
}



- (Report *) insertReportFromText:(NSString *)string
{
	//NSLog(@"%@", string);
	NSUInteger report_id=0;
	Report *insertedReport = nil;
	
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	NSEnumerator *enu = [lines objectEnumerator];
	NSString *oneLine;
	
	// first line = headers
	
	oneLine = [enu nextObject];
	NSArray *column_names = [oneLine componentsSeparatedByString:@"\t"];
	
	NSString *prev_until_date = @"";
	
	while(oneLine = [enu nextObject])
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
			// probably monthly report
			from_date = [oneLine getValueForNamedColumn:@"Start Date" headerNames:column_names];
			
			units = [[oneLine getValueForNamedColumn:@"Quantity" headerNames:column_names] intValue];
			company_name = [oneLine getValueForNamedColumn:@"Artist/Show/Developer" headerNames:column_names];
			title	= [oneLine getValueForNamedColumn:@"Title" headerNames:column_names];
			royalty_currency	= [oneLine getValueForNamedColumn:@"Partner Share Currency" headerNames:column_names];
			royalty_price = [[oneLine getValueForNamedColumn:@"Partner Share" headerNames:column_names] doubleValue];
			country_code	= [oneLine getValueForNamedColumn:@"Country Of Sale" headerNames:column_names];
			
			
			financial_report = YES;
			
		}
		
		
		// free:headers Developer	Title/Application	Product Type Identifier	Units	Partner Share	Partner Share Currency	Customer Price	Customer Currency	Country Code	Apple Identifier	Vendor Identifier
		
		
		if (from_date&&until_date&&appID&&vendor_identifier&&company_name&&title&&type_id&&units&&royalty_currency&&customer_currency&&country_code)
		{
			if ((!report_id)||(![prev_until_date isEqualToString:until_date]))   // added: possibly multiple different rows from different reports
			{  // detect report type from first line
				
				NSDate *tmp_from_date = [from_date dateFromString];
				NSDate *tmp_until_date = [until_date dateFromString];
				
				if (financial_report)
				{
					// is a monthly report
					ReportRegion inferred_region = [[DB countryForCode:country_code] reportRegion];

					if ([self reportIDForDateString:until_date type:ReportTypeFinancial region:inferred_region]) return nil;
					
					insertedReport = [self insertReportWithType:ReportTypeFinancial from_date:tmp_from_date until_date:tmp_until_date downloaded_date:[NSDate date] region:inferred_region];
					report_id= insertedReport.primaryKey;
				}
				else if ([from_date isEqualToString:until_date])
				{	// day report

					if ([self reportIDForDateString:from_date type:ReportTypeDay region:ReportRegionUnknown]) return nil;

					insertedReport = [self insertReportWithType:ReportTypeDay from_date:tmp_from_date until_date:tmp_until_date downloaded_date:[NSDate date] region:ReportRegionUnknown];
					report_id= insertedReport.primaryKey;
				}
				else
				{	// week report
					if ([self reportIDForDateString:until_date type:ReportTypeWeek region:ReportRegionUnknown]) return nil;

					insertedReport = [self insertReportWithType:ReportTypeWeek from_date:tmp_from_date until_date:tmp_until_date downloaded_date:[NSDate date] region:ReportRegionUnknown];
					report_id= insertedReport.primaryKey;
				}
				
				if (!insertedReport)
				{
					// if we could not insert it, it's probably already in DB
					return nil;
				}
			}
			
			if (insertedReport)
			{
				if (![DB appForID:appID])
				{
					
					[DB insertAppWithTitle:title vendor_identifier:vendor_identifier apple_identifier:appID company_name:company_name];
					
				}
				
				[insertedReport insertSaleForAppID:appID type_id:type_id units:units royalty_price:royalty_price royalty_currency:royalty_currency customer_price:customer_price customer_currency:customer_currency country_code:country_code];
			}
			
		}
		else
		{
			// lines that don't match the headers, most likey empty lines after the report
		} 
		
		prev_until_date = until_date;
	}
	
	
	[insertedReport makeSummariesFromSales];
	return insertedReport;
}




- (NSUInteger) reportIDForDateString:(NSString *)dayString type:(ReportType)report_type region:(ReportRegion)report_region
{
	static sqlite3_stmt *reportid_statement = nil;

	NSUInteger retID = 0;
	NSDate *tmpDate = [dayString dateFromString];
	// Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
	if (reportid_statement == nil) {
		// Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
		// This is a great way to optimize because frequently used queries can be compiled once, then with each
		// use new variable values can be bound to placeholders.
		const char *sql = "SELECT [id] from report WHERE until_date like ? AND report_type_id = ? AND report_region_id = ?";
		if (sqlite3_prepare_v2(database, sql, -1, &reportid_statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
	}
	// For this query, we bind the primary key to the first (and only) placeholder in the statement.
	// Note that the parameters are numbered from 1, not from 0.
	
	sqlite3_bind_text(reportid_statement, 1, [[NSString stringWithFormat:@"%@%%", [[tmpDate description] substringToIndex:10]] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(reportid_statement, 2, (int)report_type);
	sqlite3_bind_int(reportid_statement, 3, (int)report_region);
	
	if (sqlite3_step(reportid_statement) == SQLITE_ROW) 
	{
		retID = sqlite3_column_int(reportid_statement, 0);
	} else {
	}
	// Reset the statement for future reuse.
	sqlite3_reset(reportid_statement);
	return retID;
}

#pragma mark Misc

- (void) reloadAllAppIcons
{
	for (NSNumber *oneAppID in apps)
	{
		App *oneApp = [apps objectForKey:oneAppID];
		oneApp.iconImage = nil;
		oneApp.iconImageNano = nil;
		[oneApp loadImageFromBirne];
	}
}

- (void) removeAllReviewTranslations
{
	for (NSNumber *oneAppID in apps)
	{
		App *oneApp = [apps objectForKey:oneAppID];
		[oneApp removeReviewTranslations];
	}
	
	
	// fast removal directly in DB
	
	NSString *script = @"update review set review_translated = NULL";	
	char *errmsg;
	
	if (sqlite3_exec(database, [script UTF8String], NULL, NULL, &errmsg)!=SQLITE_OK)
	{
 		sqlite3_close(database);
        NSAssert1(0, @"Failed to execute update script with message '%s'.", errmsg);
	}
}


#pragma mark Import / Export
- (NSString *) createZipFromReportsOfType:(ReportType)type
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *type_string;
	NSString *file_prefix;
	
	switch (type) {
		case ReportTypeDay:
			type_string = @"daily";
			file_prefix = @"S_D_";
			break;
		case ReportTypeWeek:
			type_string = @"weekly";
			file_prefix = @"S_W_";
			break;
		default:
			// need to set a case for different types, because otherwise Analyze complains
			type_string = nil;
			file_prefix = nil;
			
			break;
	}
	NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"reports_%@.zip", (NSString *)type_string]];
	
	ZipArchive *zip = [[ZipArchive alloc] init];
	
	[zip CreateZipFile2:path]; 
	
	NSEnumerator *enu = [[self sortedReportsOfType:type] objectEnumerator];
	Report *oneReport;
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"yyyyMMdd"];
	
	
	while (oneReport = [enu nextObject]) 
	{
		NSString *s = [oneReport reconstructText];
		NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
		NSString *nameInZip = [NSString stringWithFormat:@"reports/%@%@.txt", file_prefix, [df stringFromDate:oneReport.fromDate]];
		[zip addDataAsFileToZip:d newname:nameInZip fileDate:oneReport.downloadedDate];
	}
	
	[df release];
	[zip CloseZipFile2];
	[zip release];
	
	return path;
}

- (void) importReportsFromDocumentsFolder
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
	// NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	
	// get list of all files in document directory
	NSArray *docs = [fileManager directoryContentsAtPath:documentsDirectory];
	NSEnumerator *enu = [docs objectEnumerator];
	NSString *aString;
	
	while (aString = [enu nextObject])
	{
		if ([[aString lowercaseString] hasSuffix:@".txt"])
		{
			//NSLog(@"Found report %@", aString);
			NSString *pathOfFile = [documentsDirectory stringByAppendingPathComponent:aString];
			
			NSString *string = [NSString stringWithContentsOfFile: pathOfFile encoding:NSUTF8StringEncoding error:NULL];
			[self insertReportFromText:string];
			[fileManager removeItemAtPath:pathOfFile error:NULL];
		}
		else if ([[aString lowercaseString] hasSuffix:@".zip"])
		{
			//NSLog(@"Found report archive %@", aString);
			NSString *pathOfFile = [documentsDirectory stringByAppendingPathComponent:aString];
			//NSString *unzipDir = [documentsDirectory stringByAppendingPathComponent:@"unzipped"];
			
			
			ZipArchive *zip = [[ZipArchive alloc] init];
			
			[zip UnzipOpenFile:pathOfFile];
			NSArray *datas = [zip UnzipFileToDataArray];
			
			if (!self.dataToImport)
			{
				self.dataToImport = [NSMutableArray arrayWithArray:datas];
			}
			else
			{
				[self.dataToImport addObjectsFromArray:datas];
			}
			
			/*
			 NSEnumerator *enu = [datas objectEnumerator];
			 NSData *oneData;
			 
			 while (oneData = [enu nextObject]) 
			 {
			 NSString *string = [[NSString alloc] initWithBytes:[oneData bytes] length:[oneData length] encoding:NSUTF8StringEncoding];
			 [self addReportToDBfromString:string];
			 [string release];
			 }
			 */
			
			[zip CloseZipFile2];
			[zip release];
			[fileManager removeItemAtPath:pathOfFile error:NULL];
			
			[NSTimer scheduledTimerWithTimeInterval: 0.5
											 target: self
										   selector: @selector(workImportQueue:)
										   userInfo: nil
											repeats: NO];
			
			
			//NSString *string = [NSString stringWithContentsOfFile:pathOfFile];
			//[self addReportToDBfromString:string];
			//[fileManager removeItemAtPath:pathOfFile error:NULL];
		}
		
		
	}
}


- (void)workImportQueue:(id)sender
{
	if (!dataToImport) return;
	
	NSData *oneData = [dataToImport objectAtIndex:0];
	NSString *string = [[NSString alloc] initWithBytes:[oneData bytes] length:[oneData length] encoding:NSUTF8StringEncoding];
	[self insertReportFromText:string];
	[string release];
	
	[dataToImport removeObject:oneData];
	
	if ([dataToImport count]>0)
	{
		[self setStatus:[NSString stringWithFormat:@"Importing Reports (%d left)", [dataToImport count]]];
		
		[NSTimer scheduledTimerWithTimeInterval: 1.5
										 target: self
									   selector: @selector(workImportQueue:)
									   userInfo: nil
										repeats: NO];
		
	}
	else
	{
		[self setStatus:@"Importing Reports Done"];
		[self setStatus:nil];
		
		[dataToImport release];
		dataToImport = nil;
		
		[self calcAvgRoyaltiesForApps];  // this causes avgRoyalties calc
		[self getTotals];
		
	}
}

#pragma mark Summing
- (void)calcAvgRoyaltiesForApps
{
	// for calculations wee need the latest reports hydrated
	
	
	[[self latestReportOfType:ReportTypeDay] hydrate];
	[[self latestReportOfType:ReportTypeWeek] hydrate];
	
	
	
	// day reports, they are sorted newest first
	NSArray *dayReports = [self sortedReportsOfType:ReportTypeDay];
	
	
	NSArray *appIDs = [apps allKeys];
	App *tmpApp;
	NSNumber *app_id;
	
	int i;
	
	int num_reports = [dayReports count];
	if (num_reports>7)
	{
		num_reports = 7;
	}
	
	for (i=0;i<num_reports;i++)
	{
		Report *tmpReport = [dayReports objectAtIndex:i];
		[tmpReport hydrate];
		
		
		// for each app add the royalties into the apps's average field, we'll divide it in the end
		NSEnumerator *keyEnum = [appIDs objectEnumerator];
		
		while (app_id = [keyEnum nextObject])
		{
			tmpApp = [apps objectForKey:app_id];
			
			if (!i) tmpApp.averageRoyaltiesPerDay = 0;
			
			double dayRoyalties = [tmpReport sumRoyaltiesForAppId:[app_id intValue] transactionType:TransactionTypeSale];
			tmpApp.averageRoyaltiesPerDay += dayRoyalties;
			
			if (i==(num_reports-1)) tmpApp.averageRoyaltiesPerDay = tmpApp.averageRoyaltiesPerDay/(double)num_reports;
		}
	}
	
	// we could refresh the app table
}


- (void)getTotals
{
	// return dictionary
	NSMutableDictionary *byAppDict = [NSMutableDictionary dictionary];
	NSMutableDictionary *byReportDict = [NSMutableDictionary dictionary];
	
	static sqlite3_stmt *total_statement = nil;
	
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
	

	// sometimes the notifications come in the wrong order, i.e. first the view then the apps
	// so we update directly
	for (NSNumber *oneAppKey in [apps allKeys])
	{
		App *oneApp = [apps objectForKey:oneAppKey];
		[oneApp updateTotalsFromDict:retDict];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AppTotalsUpdated" object:nil userInfo:(id)retDict];
}


#pragma mark Notification Sending
- (void) sendNewAppNotification:(App *)app
{
	NSArray *sortedApps = [self appsSortedBySales];
	
	NSIndexPath *tmpIndex = [NSIndexPath indexPathForRow:[sortedApps indexOfObject:app] inSection:0];
	
	NSArray *insertIndexPaths = [NSArray arrayWithObjects:
								 tmpIndex,
								 nil];
	
	NSArray *values = [NSArray arrayWithObjects:insertIndexPaths, app, [NSNumber numberWithInt:tmpIndex.row], [NSNumber numberWithInt:newApps], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"InsertIndexPaths", @"App", @"InsertionIndex", @"NewApps", nil];
	
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewAppAdded" object:nil userInfo:tmpDict];
}

- (void) sendNewReportNotification:(Report *)report
{
	NSArray *sortedReports = [self sortedReportsOfType:report.reportType];
	
	NSIndexPath *tmpIndex = [NSIndexPath indexPathForRow:[sortedReports indexOfObject:report] inSection:report.reportType];
	
	
	NSArray *insertIndexPaths = [NSArray arrayWithObjects:
								 tmpIndex,
								 nil];
	
	NSArray *values = [NSArray arrayWithObjects:insertIndexPaths, report, [NSNumber numberWithInt:tmpIndex.row], [NSNumber numberWithInt:newReports], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"InsertIndexPaths", @"Report", @"InsertionIndex", @"NewReports", nil];
	
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewReportAdded" object:nil userInfo:tmpDict];
}

- (void) setStatus:(NSString *)message
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"StatusMessage" object:nil userInfo:(id)message];
}



#pragma mark Notification Listening
- (void) newReportRead:(Report *)report;
{
	if (!report.isNew)
	{
		return;
	}
	
	// new code for local tracking of number of daily/weekly
	NSNumber *typeKey = [NSNumber numberWithInt:report.reportType];
	NSNumber *theNum = [newReportsByType objectForKey:typeKey];
	if (theNum)
	{
		NSNumber *newNum = [NSNumber numberWithInt:[theNum intValue]-1];
		[newReportsByType setObject:newNum forKey:typeKey];
	}
	
	// old code for notification
	report.isNew = NO;
	newReports--;
	
	NSArray *values = [NSArray arrayWithObjects:report, [NSNumber numberWithInt:newReports], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"Report", @"NewReports", nil];
	
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	
	// refresh Badges
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewReportRead" object:nil userInfo:tmpDict];
	
}

- (void)exchangeRatesChanged:(NSNotification *) notification
{
	// different exchange rates require that we redo the totals
	[DB getTotals]; 
}


@end