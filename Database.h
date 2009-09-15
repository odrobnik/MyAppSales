//
//  Database.h
//  ASiST
//
//  Created by Oliver on 28.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define DB [Database sharedInstance]

typedef enum { ReportTypeDay = 0, ReportTypeWeek = 1, ReportTypeFinancial = 2, ReportTypeFree = 3 } ReportType;
typedef enum { ReportRegionUnknown = 0, ReportRegionUSA = 1, ReportRegionEurope = 2, ReportRegionCanada = 3, ReportRegionAustralia = 4, ReportRegionUK = 5, ReportRegionJapan = 6, ReportRegionRestOfWorld = 7} ReportRegion;

@class App, Report, Country;

@interface Database : NSObject 
{
	// Opaque reference to the SQLite database.
    sqlite3 *database;
	
	// "tables", primary key is dictionary key
	NSMutableDictionary *apps;
	NSMutableDictionary *reports;
	NSMutableDictionary *countries;
	
	// indexes
	NSMutableDictionary *reportsByReportType;
	
	// counters for new tags on tab icons
	int newApps;
	int newReports;
	NSMutableDictionary *newReportsByType;
	
	// import from directory
	NSMutableArray *dataToImport;
}

@property (nonatomic, readonly)  sqlite3 *database;

@property (nonatomic, retain, readonly) NSMutableDictionary *apps;	
@property (nonatomic, retain, readonly) NSMutableDictionary *reports;  
@property (nonatomic, retain, readonly) NSMutableDictionary *countries;

+ (Database *) sharedInstance;

- (NSArray *) sortedReportsOfType:(ReportType)type;
- (Report *) latestReportOfType:(ReportType)type;
- (Report *) reportNewerThan:(Report *)aReport;
- (Report *) reportOlderThan:(Report *)aReport;
- (NSArray *) allReports;

- (App *) appForID:(NSUInteger)appID;
- (Report *) reportForID:(NSUInteger)reportID;
- (Country *) countryForCode:(NSString *)code;
- (NSUInteger) countOfApps;
- (NSUInteger) countOfReportsForType:(ReportType)type;

- (NSArray *) appsSortedBySales;

- (App *) insertAppWithTitle:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name;
- (Report *) insertReportWithType:(ReportType)type from_date:(NSDate *)from_date until_date:(NSDate *)until_date downloaded_date:(NSDate *)downloaded_date region:(ReportRegion)region;


- (Report *) insertMonthlyFreeReportFromFromDict:(NSDictionary *)dict;
- (Report *) insertReportFromText:(NSString *)string;


- (BOOL) hasNewReportsOfType:(ReportType)type;

- (void) newReportRead:(Report *)report;

- (void) reloadAllAppIcons;

- (void) importReportsFromDocumentsFolder;
- (NSString *) createZipFromReportsOfType:(ReportType)type;
- (void) getTotals; 

// used by iTunesConnect to check if report has been downloaded already
- (NSUInteger) reportIDForDateString:(NSString *)dayString type:(ReportType)report_type region:(ReportRegion)report_region;



@end
