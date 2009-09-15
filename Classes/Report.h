//
//  Report.h
//  ASiST
//
//  Created by Oliver Drobnik on 24.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sale.h"
#import "Database.h"



@interface Report : NSObject 
{
	NSUInteger primaryKey;
	ReportType reportType;
	NSDate *fromDate;
	NSDate *untilDate;
	NSDate *downloadedDate;
	
	// Internal state variables. Hydrated tracks whether attribute data is in the object or the database.
    BOOL hydrated;
	// Dirty tracks whether there are in-memory changes to data which have no been written to the database.
    BOOL dirty;
	
	// This is set to true if it was added during this session
	BOOL isNew;
	
	// Opaque reference to the underlying database.
    sqlite3 *database;
	
	// Array with sales, empty before hydrated
	NSMutableArray *sales;
	NSMutableDictionary *salesByApp;
	NSMutableDictionary *summariesByApp;
	
	NSDictionary *sumsByCurrency; // this dictionary is passed from the totals notification
	
	// sums
	NSInteger sumUnitsSold;
	NSInteger sumUnitsUpdated;
	NSInteger sumUnitsRefunded;
	
	NSInteger sumUnitsFree;
	double sumRoyaltiesEarned;
	
	// for financial reports we need region
	ReportRegion region;
}


- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (id)initWithType:(ReportType)type from_date:(NSDate *)from_date until_date:(NSDate *)until_date downloaded_date:(NSDate *)downloaded_date region:(ReportRegion)report_region database:(sqlite3 *)db;

- (Sale *) insertSaleForAppID:(NSUInteger)app_id type_id:(NSUInteger)type_id units:(NSUInteger)units
			  royalty_price:(double)royalty_price royalty_currency:(NSString *)royalty_currency 
			 customer_price:(double)customer_price customer_currency:(NSString *)customer_currency 
			   country_code:(NSString *)country_code;


- (void)insertIntoDatabase:(sqlite3 *)db;
- (void)deleteFromDatabase;
- (void)hydrate;

- (NSString *)listDescription;

// Property exposure for primary key and other attributes. The primary key is 'assign' because it is not an object, 
// nonatomic because there is no need for concurrent access, and readonly because it cannot be changed without 
// corrupting the database.
@property (assign, nonatomic, readonly) NSUInteger primaryKey;
@property (assign, nonatomic) ReportType reportType;
@property (assign, nonatomic) ReportRegion region;

// The remaining attributes are copied rather than retained because they are value objects.

@property (copy, nonatomic) NSDate *fromDate;
@property (copy, nonatomic) NSDate *untilDate;
@property (copy, nonatomic) NSDate *downloadedDate;
@property (readonly, nonatomic) NSMutableArray *sales;
@property (readonly, nonatomic) NSMutableDictionary *salesByApp;
@property (readonly, nonatomic) NSMutableDictionary *summariesByApp;
//@property (readonly, nonatomic) NSMutableDictionary *countrySummaries;

@property (assign, nonatomic) BOOL isNew;

@property (assign, nonatomic) NSInteger sumUnitsSold;
@property (assign, nonatomic) NSInteger sumUnitsUpdated;
@property (assign, nonatomic) NSInteger sumUnitsRefunded;
@property (assign, nonatomic) NSInteger sumUnitsFree;

//@property (assign, nonatomic) double sumRoyaltiesEarned;  // replaced with method

- (NSInteger) sumUnitsForAppId:(NSUInteger)app_id transactionType:(TransactionType)ttype;
- (NSInteger) sumRefundsForAppId:(NSUInteger)app_id;
- (double) sumRoyaltiesForAppId:(NSUInteger)app_id transactionType:(TransactionType)ttype;

- (double) sumRoyaltiesForAppId:(NSUInteger)app_id inCurrency:(NSString *)curCode;
- (double) sumRoyaltiesEarned;

- (NSString *) reconstructText;

- (void) makeSummariesFromSales;
- (void) hydrate;


- (NSComparisonResult)compareByReportDateDesc:(Report *)otherObject;
- (NSUInteger) day;


@end
