//
//  BirneConnect.h
//  ASiST
//
//  Created by Oliver Drobnik on 19.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
// This includes the header for the SQLite library.
#import <sqlite3.h>

typedef enum { ReportTypeDay = 0, ReportTypeWeek = 1, ReportTypeFinancial = 2, ReportTypeFree = 3 } ReportType;

@class Report, App, YahooFinance;

@interface BirneConnect : NSObject 
{
	// login
	NSString *username;
	NSString *password;
	
	
	// for HTTP
	NSMutableData *receivedData;
	NSURLConnection *theConnection;
	
	NSString *loginPostURL;
	int loginStep;
	
	// Opaque reference to the SQLite database.
    sqlite3 *database;
	
	// Currency converter
	YahooFinance *myYahoo;

	
	NSString *downloadPostURL;
	
	// array to hold available daily reports and index of currently loading report
	NSArray *dayOptions;
	int dayOptionsIdx;

	// array to hold available weekly reports and index of currently loading report
	NSArray *weekOptions;
	int weekOptionsIdx;
	
	// Date formatter for reading dates in reports from apple
	NSDateFormatter *dateFormatterToRead;

	// in-memory tables
	NSMutableDictionary *apps;
	NSMutableDictionary *reports;
	
	// indexes by type
	NSMutableArray *reportsByType;
	NSMutableArray *reportsDaily;
	NSMutableArray *reportsWeekly;

	NSMutableDictionary *latestReportsByType;
	
	// list of countries
	NSMutableDictionary *countries;
	
	// counters for new tags on tab icons
	int newApps;
	int newReports;

	NSMutableDictionary *newReportsByType;
	BOOL syncing;
	
	NSDate *lastSuccessfulLoginTime;
	
	
	NSMutableArray *dataToImport;
}


- (id) initWithLogin:(NSString *)user password:(NSString *)pass;


- (NSArray *) optionsFromSelect:(NSString *)string;

- (void)createEditableCopyOfDatabaseIfNeeded;
- (void)initializeDatabase;
- (void)refreshIndexes;


- (void) addReportToDBfromString:(NSString *)string;
//- (NSUInteger) getIDforApp:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name;
- (void) insertReportLineForAppID:(NSUInteger)app_id type_id:(NSUInteger)type_id units:(NSUInteger)units
					royalty_price:(double)royalty_price royalty_currency:(NSString *)royalty_currency customer_price:(double)customer_price customer_currency:(NSString *)customer_currency country_code:(NSString *)country_code report_id:(NSUInteger)report_id;
- (NSUInteger) reportIDForDate:(NSString *)dayString type:(ReportType)type;
- (NSUInteger)insertReportForDate:(NSString *)dayString UntilDate:(NSString *)until_date type:(ReportType)type;

- (BOOL) requestDailyReport;
- (BOOL) requestWeeklyReport;

- (NSDate *) dateFromString:(NSString *)dateString;

@property (nonatomic, retain) NSMutableDictionary *apps;
@property (nonatomic, retain) NSMutableDictionary *reports;
@property (nonatomic, readonly) NSMutableArray *reportsByType;
@property (nonatomic, readonly) NSMutableDictionary *countries;
@property (nonatomic, readonly) NSMutableDictionary *latestReportsByType;
// login
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

@property (nonatomic, retain) NSDate *lastSuccessfulLoginTime;

@property (nonatomic, readonly) sqlite3 *database;
@property (nonatomic, retain) YahooFinance *myYahoo;

@property (nonatomic, retain) NSMutableArray *dataToImport;



- (void) setStatus:(NSString *)message;
- (void) toggleNetworkIndicator:(BOOL)isON;
- (void) importReportsFromDocumentsFolder;

// helper function
- (NSString *) getValueForNamedColumn:(NSString *)column_name fromLine:(NSString *)one_line headerNames:(NSArray *)header_names;


- (void) loadCountryList;
- (NSArray *) salesCurrencies;

- (NSString *) reportTextForID:(NSInteger)report_id;
- (NSUInteger) reportIDForDate:(NSString *)dayString type:(ReportType)report_type;

- (void)refreshIndexes;
- (void)calcAvgRoyaltiesForApps;

- (void) loginAndSync;
- (void) sync;


// to know where to animate row insertion and send program-wide notification
- (NSIndexPath *) indexforApp:(App *)app;
- (NSIndexPath *) indexforReport:(Report *)report;

// to get the apps pre-sorted by the royalites field
- (NSArray *) appKeysSortedBySales;
- (NSArray *) appsSortedBySales;
//- (NSArray *) reportsSortedByDate;

- (NSString *) createZipFromReportsOfType:(ReportType)type;

- (void) newReportRead:(Report *)report;

- (NSUInteger) numberOfNewReportsOfType:(NSUInteger)reportType;


@end
