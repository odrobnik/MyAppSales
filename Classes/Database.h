//
//  Database.h
//  ASiST
//
//  Created by Oliver on 28.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "ReportTypes.h"

#define DB [Database sharedInstance]


@class App, InAppPurchase, Product_v1, Report_v1, Country_v1, AppGrouping, GenericAccount;

@interface Database : NSObject 
{
	// Opaque reference to the SQLite database.
    sqlite3 *database;
	
	// "tables", primary key is dictionary key
	NSMutableDictionary *apps;
	NSMutableDictionary *iaps;
	
	NSMutableDictionary *reports;
	NSMutableDictionary *countries;
	NSDictionary *languages;
	
	// indexes
	NSMutableDictionary *reportsByReportType;
	
	// counters for new tags on tab icons
	int newApps;
	int newReports;
	NSMutableDictionary *newReportsByType;
	NSMutableArray *appGroupings;
	
	// import from directory
	NSMutableArray *dataToImport;
}

@property (nonatomic, readonly)  sqlite3 *database;

@property (nonatomic, retain, readonly) NSMutableDictionary *apps;	
@property (nonatomic, retain, readonly) NSMutableDictionary *iaps;
@property (nonatomic, retain, readonly) NSMutableDictionary *reports;  
@property (nonatomic, retain, readonly) NSMutableDictionary *countries;
@property (nonatomic, retain, readonly) NSDictionary *languages;

+ (Database *) sharedInstance;

- (NSArray *) sortedReportsOfType:(ReportType)type;
- (Report_v1 *) latestReportOfType:(ReportType)type;
- (Report_v1 *) reportNewerThan:(Report_v1 *)aReport;
- (Report_v1 *) reportOlderThan:(Report_v1 *)aReport;
- (NSArray *) allReports;
- (NSArray *) allReportsWithAppGrouping:(AppGrouping *)appGrouping;

- (AppGrouping *) appGroupingForID:(NSInteger)groupingID;
- (AppGrouping *) appGroupingForProduct:(Product_v1 *)product;
- (AppGrouping *) appGroupingForReport:(Report_v1 *)report;

- (App *) appForID:(NSUInteger)appID;
- (App *) appForVendorID:(NSString *)vendorID;
- (InAppPurchase *) iapForID:(NSUInteger)iapID;
- (NSArray *) iapsForApp:(App *)app;
- (Report_v1 *) reportForID:(NSUInteger)reportID;
- (Country_v1 *) countryForCode:(NSString *)code;
- (NSUInteger) countOfApps;
- (NSUInteger) countOfReportsForType:(ReportType)type;

- (NSArray *) allApps;
- (NSArray *) appsSortedBySales;
- (NSArray *) appsSortedBySalesWithGrouping:(AppGrouping *)grouping;
- (NSArray *) productsSortedBySalesForGrouping:(AppGrouping *)grouping;

- (App *) insertAppWithTitle:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name;
- (InAppPurchase *) insertIAPWithTitle:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name parent:(App *)parentApp;

//- (Report *) insertReportWithType:(ReportType)type from_date:(NSDate *)from_date until_date:(NSDate *)until_date downloaded_date:(NSDate *)downloaded_date region:(ReportRegion)region;

- (void) insertMonthlyFreeReportFromFromDict:(NSDictionary *)dict;
- (void) insertReportFromText:(NSString *)string fromAccount:(GenericAccount *)account;
- (void) insertReportFromDict:(NSDictionary *)dict;


- (BOOL) hasNewReportsOfType:(ReportType)type;

- (void) newReportRead:(Report_v1 *)report;

- (void) unloadReports;
- (void) reloadAllAppIcons;
- (void) removeAllReviewTranslations;
- (void)removeReport:(Report_v1 *)report;

- (void) importReportsFromDocumentsFolder;
- (NSString *) createZipFromReportsOfType:(ReportType)type;
//- (void) getTotals; 

// used by iTunesConnect to check if report has been downloaded already
- (Report_v1 *) reportForDate:(NSDate *)reportDate type:(ReportType)reportType region:(ReportRegion)reportRegion appGrouping:(AppGrouping *)appGrouping;
//- (NSUInteger) reportIDForDateString:(NSString *)dayString type:(ReportType)report_type region:(ReportRegion)report_region;


@end
