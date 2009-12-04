//
//  Product.h
//  ASiST
//
//  Created by Oliver on 25.11.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class App;

@interface Product : NSObject {
	// fields
	NSString *title;
	NSString *vendor_identifier;
	NSUInteger apple_identifier;
	NSString *company_name;
	
	// Internal state variables. Hydrated tracks whether attribute data is in the object or the database.
    //BOOL hydrated;
	// Dirty tracks whether there are in-memory changes to data which have no been written to the database.
    BOOL dirty;
	
	// This is set to true if it was added during this session
	BOOL isNew;
	
	// Opaque reference to the underlying database.
    sqlite3 *database;
	
	// for sorting by average daily sales
	double averageRoyaltiesPerDay;
	
	// sums
	double totalRoyalties;
	int totalUnits;
	
	NSMutableDictionary *sumsByCurrency; // this dictionary is passed from the totals notification
}

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (id) initWithTitle:(NSString *)a_title vendor_identifier:(NSString *)a_vendor_identifier apple_identifier:(NSUInteger)a_apple_identifier company_name:(NSString *)a_company_name database:(sqlite3 *)db;

- (void)insertIntoDatabase:(sqlite3 *)db;
- (void)deleteFromDatabase;
- (void)updateInDatabase;    // used if title changes

// Property exposure for primary key and other attributes. The primary key is 'assign' because it is not an object, 
// nonatomic because there is no need for concurrent access, and readonly because it cannot be changed without 
// corrupting the database.
@property (assign, nonatomic) NSUInteger apple_identifier;
// The remaining attributes are copied rather than retained because they are value objects.
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *vendor_identifier;
@property (copy, nonatomic) NSString *company_name;
@property (assign, nonatomic) BOOL isNew;

@property (assign, nonatomic) double averageRoyaltiesPerDay;
@property (assign, readonly, nonatomic) double totalRoyalties;
@property (assign, readonly, nonatomic) int totalUnits;


- (NSComparisonResult)compareBySales:(Product *)otherIAP;


//- (void) updateTotalsFromDict:(NSDictionary *)totalsDict;

- (NSNumber *) identifierAsNumber;

-(void)loadSumsFromCache;
- (void)emptyCache:(NSNotification *) notification;

@end
