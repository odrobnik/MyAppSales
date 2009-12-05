//
//  Database.m
//  ASiST
//
//  Created by Oliver on 28.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "Database.h"
#import "App.h"
#import "InAppPurchase.h"
#import "Report.h"
#import "Country.h"
#import "GenericAccount.h"
#import "GenericAccount+MyAppSales.h"

#import "NSString+Helpers.h"
#import "NSDate+Helpers.h"
#import "ZipArchive.h"
#import "AppGrouping.h"
#import "DDData.h"



// private methods
@interface Database ()
- (void) connect;
- (void) createEditableCopyOfDatabaseIfNeeded;
- (void) updateSchemaIfNeeded;
- (void)initializeDatabase;

- (NSMutableArray *) reportsOfType:(ReportType)reportType;
- (void) addReportToIndex:(Report *)report;

//- (void)calcAvgRoyaltiesForApps;
//- (void)getTotals;

- (void) sendNewAppNotification:(App *)app;
- (void) sendNewReportNotification:(Report *)report;
- (void) setStatus:(NSString *)message;

@property (nonatomic, retain) NSMutableDictionary *reportsByReportType;

@property (nonatomic, retain, readwrite) NSMutableDictionary *apps;
@property (nonatomic, retain, readwrite) NSMutableDictionary *iaps;
@property (nonatomic, retain, readwrite) NSMutableDictionary *reports;
@property (nonatomic, retain, readwrite) NSMutableDictionary *countries;

@property (nonatomic, retain) NSMutableArray *dataToImport;

@end

static Database *_sharedInstance;

@implementation Database

@synthesize database;
@synthesize apps, iaps, reports, countries, languages;
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
		appGroupings = [[NSMutableSet alloc] init];
		
		// connect with database
		[self createEditableCopyOfDatabaseIfNeeded];
		[self connect];
		[self updateSchemaIfNeeded];
		[self initializeDatabase];
		
		// [self calcAvgRoyaltiesForApps]; // deferred
		//[self getTotals];
		
		// subscribe to change of exchange rates
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRatesChanged:) name:@"ExchangeRatesChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:@"UIApplicationWillTerminateNotification" object:nil];
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
	[appGroupings release];
	
	// release tables
	[apps release];
	[iaps release];
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
		case 4:
			[self executeSchemaUpdate:@"update_4_to_5.sql"];
		case 5:
			[self executeSchemaUpdate:@"update_5_to_6.sql"];
		default:
			break;
	}
}

#pragma mark Loading of Tables

- (void) bulkLoadReports
{
	// Load all reports
	
    self.reports = [NSMutableDictionary dictionary];
	self.reportsByReportType = [NSMutableDictionary dictionary];
	
	char *sql;
	sqlite3_stmt *statement;
	
	sql = "SELECT from_date, until_date, downloaded_date, report_type_id, report_region_id, appgrouping_id, report.id from report left join reportappgrouping on report_id = report.id";
	
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
	{
		// We "step" through the results - once for each row.
		while (sqlite3_step(statement) == SQLITE_ROW) 
		{
			char *from_date = (char *)sqlite3_column_text(statement, 0);
			NSDate *fromDate = nil;
			
			if (from_date)
			{
				fromDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:from_date]];
			}
			
			
			char *until_date = (char *)sqlite3_column_text(statement, 1);
			NSDate *untilDate = nil;
			
			if (until_date)
			{
				untilDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:until_date]];
			}
			
			char *downloaded_date = (char *)sqlite3_column_text(statement, 2);
			NSDate *downloadedDate;
			
			if (downloaded_date)
			{
				downloadedDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:downloaded_date]];
			}
			
			ReportType reportType = sqlite3_column_int(statement, 3);
			ReportRegion region = sqlite3_column_int(statement, 4);
			
			NSUInteger groupingID = sqlite3_column_int(statement, 5);
			NSUInteger primaryKey = sqlite3_column_int(statement, 6);
			
			
			
			Report *report = [[Report alloc] initWithPrimaryKey:primaryKey database:database
													   fromDate:fromDate 
													  untilDate:untilDate 
												aDownloadedDate:downloadedDate
												   reportTypeID:reportType
												 reportRegionID:region 
												  appGroupingID:groupingID];
			
			if (report)
			{
				// also add to the indexes
				[self addReportToIndex:report];
				
				[report release];
			}
		}
	}
	// "Finalize" the statement - releases the resources associated with the statement.
	sqlite3_finalize(statement);
}

- (void) bulkLoadReportsOfType:(ReportType)reportType
{
	// Load all reports
	NSLog(@"Bulk Loading type: %d", reportType);
	
	
	// try cache first
	
	NSString *path = [NSString pathForFileInDocuments:[NSString stringWithFormat:@"index_cache_%d.dat", reportType]];
	NSData *compressed = [NSData dataWithContentsOfFile:path];
	
	if (compressed)
	{
		NSLog(@"Cache hit type %d", reportType);
		NSData *data = [compressed gzipInflate];
		
		NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		
		NSArray *lines = [string componentsSeparatedByString:@"\n"];
		
		for (NSString *oneLine in lines)
		{
			NSScanner *scanner = [NSScanner scannerWithString:oneLine];
			
			NSInteger primaryKey;
			NSTimeInterval fromDateTI;
			NSTimeInterval untilDateTI;
			NSTimeInterval downloadedDateTI;
			NSInteger region;
			NSInteger reportType;
			NSInteger groupingID;
			
			if ([scanner scanInteger:&primaryKey])
			{
				[scanner scanString:@"/" intoString:nil];
				[scanner scanDouble:&fromDateTI];
				[scanner scanString:@"/" intoString:nil];
				[scanner scanDouble:&untilDateTI];
				[scanner scanString:@"/" intoString:nil];
				[scanner scanDouble:&downloadedDateTI];
				[scanner scanString:@"/" intoString:nil];
				[scanner scanInteger:&region];
				[scanner scanString:@"/" intoString:nil];
				[scanner scanInteger:&reportType];
				[scanner scanString:@"/" intoString:nil];
				[scanner scanInt:&groupingID];
				
				
				NSDate *fromDate = [NSDate dateWithTimeIntervalSinceReferenceDate:fromDateTI];
				NSDate *untilDate = [NSDate dateWithTimeIntervalSinceReferenceDate:untilDateTI];
				NSDate *downloadedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:downloadedDateTI];
				
				Report *report = [[Report alloc] initWithPrimaryKey:primaryKey database:database
														   fromDate:fromDate 
														  untilDate:untilDate 
													aDownloadedDate:downloadedDate
													   reportTypeID:reportType
													 reportRegionID:region 
													  appGroupingID:groupingID];
				
				if (report)
				{
					// also add to the indexes
					[self addReportToIndex:report];
					
					[report release];
				}	
			}
			else
			{
				NSLog(@"FIN");
			}

		}
		
		return;
	}
	
	NSLog(@"Cache fail type %d, doing SELECT", reportType);
	
	
	char *sql;
	sqlite3_stmt *statement;
	
	sql = "SELECT from_date, until_date, downloaded_date, report_type_id, report_region_id, report.id, appgrouping_id from report where report_type_id = ?";
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
	{
		sqlite3_bind_int(statement, 1, reportType);
		
		// We "step" through the results - once for each row.
		while (sqlite3_step(statement) == SQLITE_ROW) 
		{
			char *from_date = (char *)sqlite3_column_text(statement, 0);
			NSDate *fromDate = nil;
			
			if (from_date)
			{
				fromDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:from_date]];
			}
			
			
			char *until_date = (char *)sqlite3_column_text(statement, 1);
			NSDate *untilDate = nil;
			
			if (until_date)
			{
				untilDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:until_date]];
			}
			
			char *downloaded_date = (char *)sqlite3_column_text(statement, 2);
			NSDate *downloadedDate;
			
			if (downloaded_date)
			{
				downloadedDate = [NSDate dateFromRFC2822String:[NSString stringWithUTF8String:downloaded_date]];
			}
			
			ReportType reportType = sqlite3_column_int(statement, 3);
			ReportRegion region = sqlite3_column_int(statement, 4);
			
			
			NSUInteger primaryKey = sqlite3_column_int(statement, 5);
			NSUInteger groupingID = sqlite3_column_int(statement, 6);
			
			Report *report = [[Report alloc] initWithPrimaryKey:primaryKey database:database
													   fromDate:fromDate 
													  untilDate:untilDate 
												aDownloadedDate:downloadedDate
												   reportTypeID:reportType
												 reportRegionID:region 
												  appGroupingID:groupingID];
			
			if (report)
			{
				AppGrouping *grouping = [self appGroupingForProduct:(Product *)report];
				
				if (grouping)
				{
					if (!report.appGrouping)
					{
						report.appGrouping = grouping;
						[report updateInDatabase];
					}
				}
				
				// also add to the indexes
				[self addReportToIndex:report];
				
				[report release];
			}
		}
	}
	// "Finalize" the statement - releases the resources associated with the statement.
	sqlite3_finalize(statement);
}


// Load all apps and reports
- (void)initializeDatabase 
{
	NSLog(@"Begin Init DB");
	
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
	
	NSLog(@"- Country");
	
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
	
	NSLog(@"- Apps");
	
	
	// Load all IAP Products
    self.iaps = [NSMutableDictionary dictionary];
	sql = "SELECT id FROM InAppPurchase";
	
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
			InAppPurchase *iap = [[InAppPurchase alloc] initWithPrimaryKey:primaryKey database:database];
			
			[iaps setObject:iap forKey:[NSNumber numberWithInt:primaryKey]];
			[iap release];
		}
	}
	// "Finalize" the statement - releases the resources associated with the statement.
	sqlite3_finalize(statement); 
	
	NSLog(@"- IAPs");
	
	
	// Load all AppGroupings
	// needed before the reports
	
    appGroupings = [[NSMutableArray array] retain];
	sql = "SELECT id FROM AppGrouping order by id";
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
	{
		// We "step" through the results - once for each row.
		while (sqlite3_step(statement) == SQLITE_ROW) 
		{
			// The second parameter indicates the column index into the result set.
			int primaryKey = sqlite3_column_int(statement, 0);
			
			AppGrouping *appGrouping = [[AppGrouping alloc] initWithPrimaryKey:primaryKey database:database];
			[appGroupings addObject:appGrouping];
			[appGrouping release];
		}
	}
	// "Finalize" the statement - releases the resources associated with the statement.
	sqlite3_finalize(statement);
	
	NSLog(@"- Groupings");
	
	//[self bulkLoadReports];
	NSLog(@"- Reports deferred");
	
	
	NSLog(@"End Init DB");
}

#pragma mark Accessing Database
- (BOOL)hasLoadedReportsOfType:(ReportType)reportType
{
	if (!reportsByReportType) return NO;
	
	return ([[reportsByReportType objectForKey:[NSNumber numberWithInt:reportType]] count]>0);
}

- (void)unloadReports
{
	[reports release];
	reports = nil;
	
	[reportsByReportType release];
	reportsByReportType = nil;
}


- (NSMutableArray *) reportsOfType:(ReportType)reportType
{
	if (!reportsByReportType)
	{
		self.reportsByReportType = [NSMutableDictionary dictionary];
	}
	
	NSMutableArray *reportsOfThisType = [reportsByReportType objectForKey:[NSNumber numberWithInt:reportType]];
	
	if (!reportsOfThisType)
	{
		reportsOfThisType = [NSMutableArray array];
		NSNumber *reportTypeKey = [NSNumber numberWithInt:(int)reportType];
		
		[reportsByReportType setObject:reportsOfThisType forKey:reportTypeKey];
		
		[self bulkLoadReportsOfType:reportType];
	}
	
	return reportsOfThisType;
}

- (void) addReportToIndex:(Report *)report
{
	NSMutableArray *arrayForThisType = [self reportsOfType:report.reportType];
	
	//NSLog(@"index: %d, add %@", [arrayForThisType count], report);
	
	[arrayForThisType addObject:report];
	
	if (!reports)
	{
		self.reports = [NSMutableDictionary dictionary];
	}
	[reports setObject:report forKey:[NSNumber numberWithInt:report.primaryKey]];
	
	
}




- (Report *) reportForDate:(NSDate *)reportDate type:(ReportType)reportType region:(ReportRegion)reportRegion appGrouping:(AppGrouping *)appGrouping
{
	NSArray *reportsOfThisType = [self reportsOfType:reportType];
	
	for (Report *oneReport in reportsOfThisType)
	{
		if ([oneReport.untilDate sameDateAs:reportDate]&&(oneReport.region == reportRegion))
		{
			// also check if its from the same grouping if not nil
			
			if (appGrouping)
			{
				AppGrouping *oneGrouping = [self appGroupingForReport:oneReport];
				
				if (oneGrouping == appGrouping)
				{
					return oneReport;
				}
			}
			else 
			{
				return oneReport;
			}
			
		}
	}
	
	return nil;
}


- (NSArray *) sortedReportsOfType:(ReportType)type
{
	NSArray *arrayForThisType = [self reportsOfType:type];
	
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

- (App *) appForVendorID:(NSString *)vendorID
{
	NSArray *appKeys = [apps allKeys];
	
	for (NSNumber *oneKey in appKeys)
	{
		App *oneApp = [apps objectForKey:oneKey];
		
		if ([oneApp.vendor_identifier isEqualToString:vendorID])
		{
			return oneApp;
		}
	}
	
	return nil; 
}


- (InAppPurchase *) iapForID:(NSUInteger)iapID
{
	NSNumber *iap_key = [NSNumber numberWithInt:iapID];
	return [iaps objectForKey:iap_key];
}

- (NSArray *) iapsForApp:(App *)app
{
	NSArray *iapKeys = [iaps allKeys];
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (NSNumber *oneKey in iapKeys)
	{
		InAppPurchase *oneIAP = [iaps objectForKey:oneKey];
		
		if (oneIAP.parent == app)
		{
			[tmpArray addObject:oneIAP];
		}
	}
	
	if ([tmpArray count])
	{
		return [NSArray arrayWithArray:tmpArray];
	}
	else
	{
		return nil; 
	}
}

- (Report *) reportForID:(NSUInteger)reportID
{
	NSNumber *report_key = [NSNumber numberWithInt:reportID];
	return [reports objectForKey:report_key];
}


- (NSArray *) allReports
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	NSArray *dayArray = [self reportsOfType:ReportTypeDay];
	NSArray *weekArray = [self reportsOfType:ReportTypeWeek];
	NSArray *financialArray = [self reportsOfType:ReportTypeFinancial];
	NSArray *freeArray = [self reportsOfType:ReportTypeFree];
	
	[tmpArray addObjectsFromArray:dayArray];
	[tmpArray addObjectsFromArray:weekArray];	
	[tmpArray addObjectsFromArray:financialArray];
	[tmpArray addObjectsFromArray:freeArray];
	
	return [NSArray arrayWithArray:tmpArray];  // non-mutable, autoreleased
}

- (NSArray *) allReportsWithAppGrouping:(AppGrouping *)appGrouping
{
	NSArray *allReports = [self allReports];
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (Report *oneReport in allReports)
	{
		if (oneReport.appGrouping == appGrouping)
		{
			[tmpArray addObject:oneReport];
		}
	}
	
	return [NSArray arrayWithArray:tmpArray];
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
	
	NSLog(@"Cannot resolve country name '%@', please report this to oliver@drobnik.com", countryName);
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

- (NSUInteger) countOfApps
{
	return [apps count];
}

- (NSUInteger) countOfReportsForType:(ReportType)type
{
	NSArray *arrayForThisType = [self reportsOfType:type];
	
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

- (NSArray *) iapKeysSortedBySales
{
	NSArray *sortedKeys = [iaps keysSortedByValueUsingSelector:@selector(compareBySales:)];
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

- (NSArray *) appsSortedBySalesWithGrouping:(AppGrouping *)grouping
{
	NSArray *sortedKeys = [self appKeysSortedBySales];
	NSEnumerator *enu = [sortedKeys objectEnumerator];
	NSNumber *oneKey;
	NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:[sortedKeys count]];
	
	
	while (oneKey = [enu nextObject]) {
		App *oneApp = [apps objectForKey:oneKey];
		
		if ([self appGroupingForProduct:oneApp]==grouping)
		{
			[tmpArray addObject:oneApp];
		}
	}
	
	NSArray *ret = [NSArray arrayWithArray:tmpArray];
	[tmpArray release];
	
	return ret;
}

- (NSArray *) productsSortedBySalesForGrouping:(AppGrouping *)grouping
{
	NSMutableDictionary *combinedAppAndIAP = [NSMutableDictionary dictionaryWithDictionary:apps];
	[combinedAppAndIAP addEntriesFromDictionary:iaps];
	
	NSArray *sortedKeys = [combinedAppAndIAP keysSortedByValueUsingSelector:@selector(compareBySales:)];
	
	NSEnumerator *enu = [sortedKeys objectEnumerator];
	NSNumber *oneKey;
	NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:[sortedKeys count]];
	
	
	while (oneKey = [enu nextObject]) {
		Product *oneProduct = [combinedAppAndIAP objectForKey:oneKey];
		
		if ([self appGroupingForProduct:oneProduct]==grouping)
		{
			[tmpArray addObject:oneProduct];
		}
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

#pragma mark App Grouping
- (AppGrouping *) appGroupingForID:(NSInteger)groupingID
{
	for (AppGrouping *oneGrouping in appGroupings)
	{
		if (oneGrouping.primaryKey == groupingID)
		{
			return oneGrouping;
		}
	}
	
	return nil;
}

- (AppGrouping *) appGroupingForProduct:(Product *)product
{
	NSSet *checkSet;
	
	if ([product isKindOfClass:[InAppPurchase class]])
	{
		checkSet = [NSSet setWithObjects:product, ((InAppPurchase *)product).parent, nil];
	}
	else
	{
		checkSet = [NSSet setWithObject:product];
	}
	
	for (AppGrouping *oneGrouping in appGroupings)
	{
		if ([oneGrouping containsAppsOfSet:checkSet])
		{
			return oneGrouping;
		}
	}
	
	return nil;
}


- (AppGrouping *) appGroupingForReport:(Report *)report
{
	if (report.appGrouping)
	{
		return report.appGrouping;
	}
	
	if (![report.appsInReport count])
	{
		return nil;   // empty report, we cannot determine
	}
	
	
	// make sure we have the list of apps
	[report hydrate];
	
	NSMutableArray *intersectingGroups = [NSMutableArray array];
	
	for (AppGrouping *oneGrouping in appGroupings)
	{
		if ([oneGrouping containsAppsOfSet:report.appsInReport])
		{
			[intersectingGroups addObject:oneGrouping];
		}
	}
	
	if ([intersectingGroups count]==0)
	{
		// no group yet with these apps, make new one
		AppGrouping *newGrouping = [[[AppGrouping alloc] initWithAppSet:report.appsInReport] autorelease];
		[appGroupings addObject:newGrouping];
		[newGrouping insertIntoDatabase:database];
		
		return newGrouping;
	}
	else if ([intersectingGroups count]==1)
	{
		// exactly one group, so we make sure that all apps from this report belong to it
		AppGrouping *foundGroup = [intersectingGroups lastObject];
		[foundGroup appendAppsOfSet:report.appsInReport];
		[foundGroup updateInDatabase];
		return foundGroup;
	}
	else 
	{
		// multiple groups, we need to merge down
		
		AppGrouping *groupToMergeInto = [intersectingGroups objectAtIndex:0]; //use earliest
		[groupToMergeInto appendAppsOfSet:report.appsInReport];
		
		for (AppGrouping *oneGroup in intersectingGroups)
		{
			if (oneGroup!=groupToMergeInto)
			{
				[groupToMergeInto snatchReportsFromAppGrouping:oneGroup];
				for (Report *oneReport in [self allReports])
				{
					if (oneReport.appGrouping == oneGroup)
					{
						oneReport.appGrouping = groupToMergeInto;
					}
				}
				
				[groupToMergeInto appendAppsOfSet:oneGroup.apps];
				[appGroupings removeObject:oneGroup];
				[oneGroup deleteFromDatabase];
			}
		}
		
		[groupToMergeInto updateInDatabase];
		
		return groupToMergeInto;
	}
}

#pragma mark Inserting

- (void) insertReportIfNotDuplicate:(Report *)newReport
{
	if (!newReport.fromDate || !newReport.untilDate || !newReport.downloadedDate)
	{
		NSLog(@"NULL date encountered, ignoring report");
		return;
	}
	
	Report *existingReport = [self reportForDate:newReport.untilDate type:newReport.reportType region:newReport.region appGrouping:newReport.appGrouping];
	
	// only add it if there is no previously existing report
	if (!existingReport)
	{
		// no duplicate, add it
		
		[newReport insertIntoDatabase:database]; 
		[reports setObject:newReport forKey:[NSNumber numberWithInt:newReport.primaryKey]];
		
		
		// also add it to the type index
		NSMutableArray *arrayForThisType = [self reportsOfType:newReport.reportType];
		
		/*
		 if (!arrayForThisType)
		 {
		 // this is the first report of this type, create corresponding array
		 arrayForThisType = [NSMutableArray array];
		 NSNumber *reportTypeKey = [NSNumber numberWithInt:(int)newReport.reportType];
		 [reportsByReportType setObject:arrayForThisType forKey:reportTypeKey];
		 }
		 */
		
		[arrayForThisType addObject:newReport];
		
		newReports ++;
		
		//[self calcAvgRoyaltiesForApps];
		[self sendNewReportNotification:newReport];
		
		// local number of daily/weekly new Reports tracking
		NSNumber *typeKey = [NSNumber numberWithInt:newReport.reportType];
		
		[newReportsByType setObject:[NSNumber numberWithInt:1 + [[newReportsByType objectForKey:typeKey] intValue]] forKey:typeKey];
	}
}

- (void) insertReportFromDict:(NSDictionary *)dict
{
	NSString *text = [dict objectForKey:@"Text"];
	GenericAccount *account = [dict objectForKey:@"Account"];
	ReportRegion region = [[dict objectForKey:@"Region"] intValue];
	NSDate *fallbackDate = [dict objectForKey:@"FallbackDate"];
	
	// Make a report from the text, nothing added to DB yet
	Report *newReport = [[[Report alloc] initWithReportText:text] autorelease];
	
	if (!newReport.fromDate&&fallbackDate)
	{
		newReport.fromDate = fallbackDate;
	}
	
	if (!newReport.untilDate&&fallbackDate)
	{
		newReport.untilDate = fallbackDate;
	}
	
	// this can happen if there are no sales on report
	if (newReport.region == ReportRegionUnknown)
	{
		newReport.region = region;
	}
	
	if (newReport.reportType == ReportTypeUnknown)
	{
		newReport.reportType = [[dict objectForKey:@"Type"] intValue];
	}
	
	// check for duplicate
	AppGrouping *appGrouping = [self appGroupingForReport:newReport];
	
	if (appGrouping)
	{
		newReport.appGrouping = appGrouping;
		
		// save grouping ID in account label
		[account setAppGrouping:appGrouping];
	}
	else
	{
		// try to inherit grouping from account
		
		appGrouping = [account appGrouping];
		
		if (appGrouping)
		{
			newReport.appGrouping = [account appGrouping]; 
		}
		else
		{
			return;  // to be safe ignore this for now, next time this account has a group
		}
	}
	
	if (!newReport.fromDate || !newReport.untilDate || !newReport.downloadedDate)
	{
		NSLog(@"NULL date encountered, ignoring report");
		return;
	}
	
	[self insertReportIfNotDuplicate:newReport];
}



// monthly free reports dont have beginning and end dates, thus they need to be supplied
- (void) insertMonthlyFreeReportFromFromDict:(NSDictionary *)dict
{
	// Make a report from the text, nothing added to DB yet
	Report *newReport = [[[Report alloc] initAsFreeReportWithDict:dict] autorelease];
	GenericAccount *account = [dict objectForKey:@"Account"];
	AppGrouping *appGrouping = [self appGroupingForReport:newReport];
	if (appGrouping)
	{
		newReport.appGrouping = appGrouping;
		
		// save grouping ID in account label
		[account setAppGrouping:appGrouping];
	}
	else
	{
		newReport.appGrouping = [account appGrouping]; 
	}
	
	[self insertReportIfNotDuplicate:newReport];
}

- (void) insertReportFromText:(NSString *)string fromAccount:(GenericAccount *)account
{
	// Make a report from the text, nothing added to DB yet
	Report *newReport = [[[Report alloc] initWithReportText:string] autorelease];
	
	// check for duplicate
	AppGrouping *appGrouping = [self appGroupingForReport:newReport];
	
	if (appGrouping)
	{
		newReport.appGrouping = appGrouping;
		
		// save grouping ID in account label
		[account setAppGrouping:appGrouping];
	}
	else
	{
		// try to inherit grouping from account
		
		appGrouping = [account appGrouping];
		
		if (appGrouping)
		{
			newReport.appGrouping = [account appGrouping]; 
		}
		else
		{
			return;  // to be safe ignore this for now, next time this account has a group
		}
	}
	
	[self insertReportIfNotDuplicate:newReport];
}

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

- (InAppPurchase *) insertIAPWithTitle:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name parent:(App *)parentApp
{
	NSLog(@"Added IAP: %@", title);
	// this also adds it to the database
	InAppPurchase *tmpIAP = [[InAppPurchase alloc] initWithTitle:title vendor_identifier:vendor_identifier apple_identifier:apple_identifier company_name:company_name parent:(App *)parentApp database:database];
	
	[iaps setObject:tmpIAP forKey:[NSNumber numberWithInt:apple_identifier]];
	
	return [tmpIAP autorelease];
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
	// fast removal directly in DB
	
	NSString *script = @"update review set review_translated = NULL";	
	char *errmsg;
	
	if (sqlite3_exec(database, [script UTF8String], NULL, NULL, &errmsg)!=SQLITE_OK)
	{
 		sqlite3_close(database);
        NSAssert1(0, @"Failed to execute update script with message '%s'.", errmsg);
	}
	
	for (NSNumber *oneAppID in apps)
	{
		App *oneApp = [apps objectForKey:oneAppID];
		[oneApp removeReviewTranslations];
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
			[self insertReportFromText:string fromAccount:nil];  // don't know account
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
			
			[zip CloseZipFile2];
			[zip release];
			[fileManager removeItemAtPath:pathOfFile error:NULL];
			
			[NSTimer scheduledTimerWithTimeInterval: 0.5
											 target: self
										   selector: @selector(workImportQueue:)
										   userInfo: nil
											repeats: NO];
		}
	}
	
	// update sums
	//[self calcAvgRoyaltiesForApps];  // this causes avgRoyalties calc
	//[self getTotals];
}


- (void)workImportQueue:(id)sender
{
	if (!dataToImport) return;
	
	NSData *oneData = [dataToImport objectAtIndex:0];
	NSString *string = [[NSString alloc] initWithBytes:[oneData bytes] length:[oneData length] encoding:NSUTF8StringEncoding];
	[self insertReportFromText:string fromAccount:nil];  // don't know account
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
		
		//[self calcAvgRoyaltiesForApps];  // this causes avgRoyalties calc
		//[self getTotals];
		
	}
}

/*
 #pragma mark Summing
 - (void)calcAvgRoyaltiesForApps
 {
 NSLog(@"Start Average");
 // day reports, they are sorted newest first
 NSArray *dayReports = [self sortedReportsOfType:ReportTypeDay];
 
 
 NSMutableDictionary *combinedAppAndIAP = [NSMutableDictionary dictionaryWithDictionary:apps];
 [combinedAppAndIAP addEntriesFromDictionary:iaps];
 NSArray *appIDs = [combinedAppAndIAP allKeys];
 
 
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
 tmpApp = [combinedAppAndIAP objectForKey:app_id];
 
 if (!i) tmpApp.averageRoyaltiesPerDay = 0;
 
 double dayRoyalties;
 
 if ([tmpApp isKindOfClass:[App class]])
 {
 dayRoyalties = [tmpReport sumRoyaltiesForProduct:tmpApp transactionType:TransactionTypeSale];
 dayRoyalties += [tmpReport sumRoyaltiesForInAppPurchasesOfApp:tmpApp];
 }
 else if ([tmpApp isKindOfClass:[InAppPurchase class]])
 {
 dayRoyalties = [tmpReport sumRoyaltiesForProduct:tmpApp transactionType:TransactionTypeIAP];
 }
 
 tmpApp.averageRoyaltiesPerDay += dayRoyalties;
 
 if (i==(num_reports-1)) tmpApp.averageRoyaltiesPerDay = tmpApp.averageRoyaltiesPerDay/(double)num_reports;
 }
 }
 
 // we could refresh the app table
 NSLog(@"End Average");
 
 }
 */
/*
 - (void)getTotals
 {
 NSLog(@"Start Totals");
 
 // return dictionary
 NSMutableDictionary *byAppDict = [NSMutableDictionary dictionary];
 NSMutableDictionary *byReportDict = [NSMutableDictionary dictionary];
 
 static sqlite3_stmt *total_statement = nil;
 
 // Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
 if (total_statement == nil) {
 // Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
 // This is a great way to optimize because frequently used queries can be compiled once, then with each
 // use new variable values can be bound to placeholders.
 const char *sql = "SELECT app_id, royalty_currency, sum(units), sum(units*royalty_price), report_id, min(report_type_id) FROM report r, sale s WHERE r.id = s.report_id and (type_id=1 or type_id=101) group by report_id, app_id, royalty_currency";
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
 
 for (NSNumber *oneIAPKey in [iaps allKeys])
 {
 InAppPurchase *oneIAP = [iaps objectForKey:oneIAPKey];
 [oneIAP updateTotalsFromDict:retDict];
 }
 [[NSNotificationCenter defaultCenter] postNotificationName:@"AppTotalsUpdated" object:nil userInfo:(id)retDict];
 
 NSLog(@"End Totals");
 }
 */

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
	
	[report notifyServerAboutReportAvailability];
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
	//[DB getTotals]; // no longer necessary
}

-(void)cacheStubsForReportsOfType:(ReportType)reportType
{
	if (![self hasLoadedReportsOfType:reportType]) return;
	
	NSLog(@"Cache type %d", reportType);
	
	NSMutableString *tmpStr = [NSMutableString string];
	
	NSMutableArray *tmpReports = [self reportsOfType:reportType];
	for (Report *oneReport in tmpReports)
	{
		NSString *stub = [oneReport stubAsString];
		
		[tmpStr appendFormat:@"%@\n", stub];
	}
	
	NSString *path = [NSString pathForFileInDocuments:[NSString stringWithFormat:@"index_cache_%d.dat", reportType]];
	NSData *data = [tmpStr dataUsingEncoding:NSUTF8StringEncoding];
	NSData *compressed = [data gzipDeflate];
	[compressed writeToFile:path atomically:NO];
}


-(void)applicationWillTerminate:(NSNotification *)notification
{
	[self cacheStubsForReportsOfType:ReportTypeDay];
	[self cacheStubsForReportsOfType:ReportTypeWeek];
	[self cacheStubsForReportsOfType:ReportTypeFinancial];
	[self cacheStubsForReportsOfType:ReportTypeFree];
}	



@end