//
//  Review.h
//  iTunesScrapingTest
//
//  Created by Oliver on 11.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "TranslationScraperOperation.h"

@class Country, App;



@interface Review  : NSObject <TranslationScraperDelegate>
{
	NSUInteger primaryKey;
	App *app;
	Country *country;
	
	NSString *title;
	NSString *name;
	NSString *version;
	NSDate *date;
	NSString *review;
	NSString *translated_review;
	
	
	double stars;
	
	BOOL isNew;
	
	// Opaque reference to the underlying database.
    sqlite3 *database;
}

@property (nonatomic, retain) App *app;
@property (nonatomic, retain) Country *country;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *review;
@property (nonatomic, retain) NSString *translated_review;
@property (nonatomic, assign) double stars;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, assign) NSUInteger primaryKey;


- (id) initWithApp:(App *)reviewApp country:(Country *)reviewCountry title:(NSString *)aTitle name:(NSString *)aName version:(NSString *)aVersion date:(NSDate *)aDate review:(NSString *)aReview stars:(double)aStars;
- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (void)insertIntoDatabase:(sqlite3 *)db;
- (void)updateDatabase;

- (NSString *)stringAsHTML;

@end
