//
//  App.h
//  ASiST
//
//  Created by Oliver Drobnik on 20.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "ReviewDownloaderOperation.h"
#import "TranslationScraperOperation.h"



@interface App : NSObject <ReviewScraperDelegate> {
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

	NSMutableArray *reviews;
	NSUInteger countNewReviews;
	
	// for Downloading Icon image
	NSMutableData *receivedData;
	NSURLConnection *theConnection;
	
	UIImage *iconImage;
	UIImage *iconImageNano;
	
	// for sorting by average daily sales
	double averageRoyaltiesPerDay;
	
	// sums
	double totalRoyalties;
	int totalUnitsSold;
	int totalUnitsFree;
	
	
	NSDictionary *sumsByCurrency; // this dictionary is passed from the totals notification
	
}

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (id) initWithTitle:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name database:(sqlite3 *)db;

- (void)insertIntoDatabase:(sqlite3 *)db;
- (void)deleteFromDatabase;
- (void)updateInDatabase;    // used if title changes

- (void) loadImageFromBirne;

// Property exposure for primary key and other attributes. The primary key is 'assign' because it is not an object, 
// nonatomic because there is no need for concurrent access, and readonly because it cannot be changed without 
// corrupting the database.
@property (assign, nonatomic) NSUInteger apple_identifier;
// The remaining attributes are copied rather than retained because they are value objects.
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *vendor_identifier;
@property (copy, nonatomic) NSString *company_name;

@property (retain, nonatomic) UIImage *iconImage;
@property (retain, nonatomic) UIImage *iconImageNano;

@property (assign, nonatomic) BOOL isNew;

@property (assign, nonatomic) double averageRoyaltiesPerDay;
@property (assign, readonly, nonatomic) double totalRoyalties;
@property (assign, readonly, nonatomic) int totalUnitsSold;
@property (assign, readonly, nonatomic) int totalUnitsFree;

@property (assign, readonly, nonatomic) NSMutableArray *reviews;

@property (nonatomic, readonly) NSUInteger countNewReviews;

- (NSComparisonResult)compareBySales:(App *)otherApp;


- (void) updateTotalsFromDict:(NSDictionary *)totalsDict;

- (void) getAllReviews;
- (void) removeReviewTranslations;
- (NSString *) reviewsAsHTML;

@end
