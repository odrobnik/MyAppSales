//
//  Review.m
//  iTunesScrapingTest
//
//  Created by Oliver on 11.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "Review.h"
#import "App.h"
#import "Country.h"

static sqlite3_stmt *insert_statement = nil;

@implementation Review

@synthesize app, country, title, name, version, date, review, stars, isNew;



- (id) initWithApp:(App *)reviewApp country:(Country *)reviewCountry title:(NSString *)aTitle name:(NSString *)aName version:(NSString *)aVersion date:(NSDate *)aDate review:(NSString *)aReview stars:(double)aStars
{
	if (self = [super init])
	{
		self.app = reviewApp;
		self.country = reviewCountry;
		self.title = aTitle;
		self.name = aName;
		self.version = aVersion;
		self.date = aDate;
		self.review = aReview;
		self.stars = aStars;
	}
	
	return self;
}

- (void) dealloc
{
	[app release];
	[country release];
	[title release];
	[name release];
	[version release];
	[date release];
	[review release];
	
	[super dealloc];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"Title: %@, Name: %@, Version: %@, Date: %@, Stars: %.2f, Review: %@", title, name, version, date, stars*5.0, review];
}


- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO review(app_id, country_code, review_date, version, title, name, review, stars) VALUES(?, ?, ?, ?, ?, ?, ?, ?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_int(insert_statement, 1, app.apple_identifier);
	sqlite3_bind_text(insert_statement, 2, [country.iso2 UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 3, [[date description]UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 4, [version UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 5, [title UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 6, [name UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 7, [review UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_double(insert_statement, 8, stars);
	
	
    int success = sqlite3_step(insert_statement);
	
	// if the review already exists success == SQLITE_CONSTRAINT;
	if (success != SQLITE_CONSTRAINT)
	{
		isNew = YES;
	}
	
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insert_statement);
	
    if (success == SQLITE_ERROR) {
        NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
    } else {
        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
        // in the database. To access this functionality, the table should have a column declared of type 
        // "INTEGER PRIMARY KEY"
        
		// Primary key already set!
		// apple_identifier = sqlite3_last_insert_rowid(database);
    }
    // All data for the book is already in memory, but has not be written to the database
    // Mark as hydrated to prevent empty/default values from overwriting what is in memory
    //hydrated = YES;
}





@end
