//
//  Report.h
//  ASiST
//
//  Created by Oliver Drobnik on 24.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BirneConnect.h"
#import "Sale.h"


@interface Report : NSObject {
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
	
	// we need a link to this for referring to apps and countries
	BirneConnect *itts;
	
	// Array with sales, empty before hydrated
	//NSMutableArray *reportsByApps;
	NSMutableArray *sales;
	NSMutableDictionary *salesByApp;
	NSMutableDictionary *summariesByApp;
	
	// sums
	NSInteger sumUnitsSold;
	NSInteger sumUnitsUpdated;
	NSInteger sumUnitsRefunded;
	double sumRoyaltiesEarned;


}


- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (id)initWithType:(ReportType)type from_date:(NSDate *)from_date until_date:(NSDate *)until_date downloaded_date:(NSDate *)downloaded_date database:(sqlite3 *)db;


- (void)insertIntoDatabase:(sqlite3 *)db;
- (void)deleteFromDatabase;
- (void)hydrate;

- (NSString *)listDescription;

@property(nonatomic, retain) 	BirneConnect *itts;


// Property exposure for primary key and other attributes. The primary key is 'assign' because it is not an object, 
// nonatomic because there is no need for concurrent access, and readonly because it cannot be changed without 
// corrupting the database.
@property (assign, nonatomic, readonly) NSUInteger primaryKey;
@property (assign, nonatomic) ReportType reportType;
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
@property (assign, nonatomic) double sumRoyaltiesEarned;

- (NSInteger) sumUnitsForAppId:(NSNumber *)app_id transactionType:(TransactionType)ttype;
- (NSInteger) sumRefundsForAppId:(NSNumber *)app_id;
- (double) sumRoyaltiesForAppId:(NSNumber *)app_id transactionType:(TransactionType)ttype;

- (NSString *) reconstructText;

- (void) hydrate;


@end
