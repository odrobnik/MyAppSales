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
#import "SynchingManager.h"

static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *update_statement = nil;
static sqlite3_stmt *reviews_statement = nil;

// Date formatter for XML files
static NSDateFormatter *dateFormatterToRead = nil;

@implementation Review

@synthesize app, country, title, name, version, date, review, translated_review, stars, isNew, primaryKey;



- (id) initWithApp:(App *)reviewApp country:(Country *)reviewCountry title:(NSString *)aTitle name:(NSString *)aName version:(NSString *)aVersion date:(NSDate *)aDate review:(NSString *)aReview stars:(double)aStars
{
	if (self = [super init])
	{
		self.app = reviewApp;
		self.country = reviewCountry;
		self.title = aTitle;
		self.name = aName;
		
		if (aVersion)
		{
			self.version = aVersion;
		}
		else 
		{
			self.version = @"-";
		}

		self.date = aDate;
		self.review = aReview;
		self.stars = aStars;
	}
	
	return self;
}

- (NSDate *) dateFromString:(NSString *)rfc2822String
{
	if (!dateFormatterToRead)
	{
		dateFormatterToRead = [[NSDateFormatter alloc] init];
		[dateFormatterToRead setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"]; /* Unicode Locale Data Markup Language */
	}
	return [dateFormatterToRead dateFromString:rfc2822String]; /*e.g. @"Thu, 11 Sep 2008 12:34:12 +0200" */	
}

// Creates the object with primary key and title is brought into memory.
- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db 
{
	self.primaryKey = pk;
	database = db;
	
    if (self = [self init]) 
	{
        if (reviews_statement == nil) {
            // Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
            // This is a great way to optimize because frequently used queries can be compiled once, then with each
            // use new variable values can be bound to placeholders.
            const char *sql = "SELECT id, country_code, review_date, version, title, name, review, stars, review_translated FROM review WHERE id=? ORDER BY review_date DESC";
            if (sqlite3_prepare_v2(database, sql, -1, &reviews_statement, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }
        // For this query, we bind the primary key to the first (and only) placeholder in the statement.
        // Note that the parameters are numbered from 1, not from 0.
        sqlite3_bind_int(reviews_statement, 1, pk);
		
        while (sqlite3_step(reviews_statement) == SQLITE_ROW) {
			//NSUInteger review_id = sqlite3_column_int(reviews_statement, 0);
			//NSLog(@"%d", review_id);
			NSString *country_code = [NSString stringWithUTF8String:(char *)sqlite3_column_text(reviews_statement, 1)];
			self.country = [DB countryForCode:country_code];
			country.usedInReport = YES; // makes sure we have an icon
			
			
			
			char *date_text = (char *)sqlite3_column_text(reviews_statement, 2);
			
			if (date_text)
			{
				self.date = [self dateFromString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(reviews_statement, 2)]];
			}
			
			char *version_text = (char *)sqlite3_column_text(reviews_statement, 3);
			
			//NSString *version = nil;
			
			if (version_text )
			{	
				self.version = [NSString stringWithUTF8String:version_text];
			}
			
			self.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(reviews_statement, 4)];			
			self.name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(reviews_statement, 5)];			
			self.review = [NSString stringWithUTF8String:(char *)sqlite3_column_text(reviews_statement, 6)];			
			stars = sqlite3_column_double(reviews_statement, 7);
			
			char *translated_text = (char *)sqlite3_column_text(reviews_statement, 8);
			NSString *review_translated;
			
			if (translated_text)
			{
				review_translated = [NSString stringWithUTF8String:translated_text];
				self.translated_review = review_translated;
			}
			else 
			{
				[[SynchingManager sharedInstance]translateReview:self delegate:self];
			}
						
        }
        // Reset the statement for future reuse.
        sqlite3_reset(reviews_statement);
    }
	
    return self;
}



- (void) dealloc
{
	[dateFormatterToRead release];
	dateFormatterToRead = nil;
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

- (NSString *)stringAsHTML
{
	NSMutableString *tmpString = [NSMutableString string];
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterMediumStyle];
	[df setTimeStyle:NSDateFormatterNoStyle];
	
	[tmpString appendFormat:@"<p><b>%@</b> (%.0f of 5)\n<br />", title, stars*5.0];
	[tmpString appendFormat:@"by %@ (%@)\n<br />Version %@ - %@\n<br />", name, country.name, version, [df stringFromDate:date]];
	[tmpString appendFormat:@"<blockquote>%@</blockquote></p>", translated_review?translated_review:review];

	return [NSString stringWithString:tmpString];
}

- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO review(app_id, country_code, review_date, version, title, name, review, stars, review_translated) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)";
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
	sqlite3_bind_text(insert_statement, 9, [translated_review UTF8String], -1, SQLITE_TRANSIENT);
	
	
    int success = sqlite3_step(insert_statement);
	
	// if the review already exists success == SQLITE_CONSTRAINT;
	if (success != SQLITE_CONSTRAINT)
	{
		isNew = YES;
		primaryKey = sqlite3_last_insert_rowid(database);
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

- (void)updateDatabase
{
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (update_statement == nil) {
        static char *sql = "UPDATE review set review_translated = ? WHERE id = ?";
        if (sqlite3_prepare_v2(database, sql, -1, &update_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_text(update_statement, 1, [translated_review UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(update_statement, 2, primaryKey);
	
    int success = sqlite3_step(update_statement);
	
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(update_statement);
	
    if (success == SQLITE_ERROR) {
        NSAssert1(0, @"Error: failed to update in database with message '%s'.", sqlite3_errmsg(database));
    }
}



- (NSString *) review
{
	if (translated_review)
	{
		return translated_review;
	}
	else 
	{
		return review;
	}
}


#pragma mark Sorting
- (NSComparisonResult)compareByReviewDate:(Review *)otherReview
{
	NSTimeInterval myTI = [self.date timeIntervalSinceReferenceDate];
	NSTimeInterval otherTI = [otherReview.date timeIntervalSinceReferenceDate];
	
	
	
	if (myTI < otherTI)
	{
		return NSOrderedDescending;
	}
	
	if (myTI > otherTI)
	{
		return NSOrderedAscending;
	}
	
	return [self.name compare:otherReview.name];  // if same date sort by reviewer
}

- (void) finishedTranslatingTextTo:(NSString *)translatedText
{
	//NSLog(@"trans: '%@' to '%@'", review, translatedText);
	self.translated_review = translatedText;
	
	[self updateDatabase];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AppReviewsUpdated" object:nil userInfo:(id)app];
}


@end
