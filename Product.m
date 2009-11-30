//
//  Product.m
//  ASiST
//
//  Created by Oliver on 25.11.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "Product.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
#import "ReviewDownloaderOperation.h"
#import "Review.h"
#import "Database.h"
#import "Country.h"
#import "SynchingManager.h"

#import "App.h"


// Static variables for compiled SQL queries. This implementation choice is to be able to share a one time
// compilation of each query across all instances of the class. Each time a query is used, variables may be bound
// to it, it will be "stepped", and then reset for the next usage. When the application begins to terminate,
// a class method will be invoked to "finalize" (delete) the compiled queries - this must happen before the database
// can be closed.
static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *delete_statement = nil;
static sqlite3_stmt *update_statement = nil;

//static sqlite3_stmt *delete_points_statement = nil;

//static sqlite3_stmt *hydrate_statement = nil;
//static sqlite3_stmt *dehydrate_statement = nil;

// Date formatter for XML files
static NSDateFormatter *dateFormatterToRead = nil;



@implementation Product
@synthesize isNew, averageRoyaltiesPerDay, apple_identifier, totalRoyalties, totalUnitsSold, totalUnitsFree;

- (id)init
{
	// default images
	if (self = [super init])
	{		
		// subscribe to total update notifications
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTotalsUpdated:) name:@"AppTotalsUpdated" object:nil];
		// subscribe to cache emptying
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyCache:) name:@"EmptyCache" object:nil];
	}
	
	return self;
}

- (void)dealloc 
{
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[sumsByCurrency release];
	[title release];
	[vendor_identifier release];
    [company_name release];
	
    [super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"Product: %@ %.2f", title, averageRoyaltiesPerDay];
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
- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    if (self = [self init]) 
	{
        apple_identifier = pk;
        database = db;
        // Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
        if (init_statement == nil) {
            // Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
            // This is a great way to optimize because frequently used queries can be compiled once, then with each
            // use new variable values can be bound to placeholders.
            const char *sql = "SELECT title, vendor_identifier, company_name FROM app WHERE id=?";
            if (sqlite3_prepare_v2(database, sql, -1, &init_statement, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }
        // For this query, we bind the primary key to the first (and only) placeholder in the statement.
        // Note that the parameters are numbered from 1, not from 0.
        sqlite3_bind_int(init_statement, 1, apple_identifier);
        if (sqlite3_step(init_statement) == SQLITE_ROW) {
            self.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 0)];
            self.vendor_identifier = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 1)];
            self.company_name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 2)];
        } else {
            self.title = @"No title";
        }
        // Reset the statement for future reuse.
        sqlite3_reset(init_statement);
        dirty = NO;
		
		
    }
	
	
    return self;
}


// used to create new apps, primary key must not be in the DB already
- (id) initWithTitle:(NSString *)a_title vendor_identifier:(NSString *)a_vendor_identifier apple_identifier:(NSUInteger)a_apple_identifier company_name:(NSString *)a_company_name database:(sqlite3 *)db
{
	if (self = [self init])
	{
		database = db;
		self.title = a_title;  // property copies it anyway, app is "dirty" after setting
		self.vendor_identifier = a_vendor_identifier;
		apple_identifier = a_apple_identifier;
		self.company_name = a_company_name;
		
		isNew = YES;
		
		[self insertIntoDatabase:database];
		
		return self;
	}
	else
	{
		return nil;
	}
	
}

- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO Product(id, title, vendor_identifier, company_name) VALUES(?, ?, ?, ?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_int(insert_statement, 1, apple_identifier);
    sqlite3_bind_text(insert_statement, 2, [title UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 3, [vendor_identifier UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insert_statement, 4, [company_name UTF8String], -1, SQLITE_TRANSIENT);
	
    int success = sqlite3_step(insert_statement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insert_statement);
	
	NSAssert2((success == SQLITE_OK) || (success >= SQLITE_ROW), @"Error: sqlite3_step failed with error %d (%s).", success, sqlite3_errmsg(database));
}

- (void)deleteFromDatabase {
    // Compile the delete statement if needed.
    if (delete_statement == nil) {
        const char *sql = "DELETE FROM Product WHERE id=?";
        if (sqlite3_prepare_v2(database, sql, -1, &delete_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_int(delete_statement, 1, apple_identifier);
    // Execute the query.
    int success = sqlite3_step(delete_statement);
    // Reset the statement for future use.
    sqlite3_reset(delete_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
    }
}

- (void)updateInDatabase {
    // Compile the delete statement if needed.
    if (update_statement == nil) {
        const char *sql = "UPDATE Product set title = ? WHERE id=?";
        if (sqlite3_prepare_v2(database, sql, -1, &update_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_text(update_statement, 1, [title UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(update_statement, 2, apple_identifier);
    // Execute the query.
    int success = sqlite3_step(update_statement);
    // Reset the statement for future use.
    sqlite3_reset(update_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to update in database with message '%s'.", sqlite3_errmsg(database));
    }
}

#pragma mark Properties
// Accessors implemented below. All the "get" accessors simply return the value directly, with no additional
// logic or steps for synchronization. The "set" accessors attempt to verify that the new value is definitely
// different from the old value, to minimize the amount of work done. Any "set" which actually results in changing
// data will mark the object as "dirty" - i.e., possessing data that has not been written to the database.
// All the "set" accessors copy data, rather than retain it. This is common for value objects - strings, numbers, 
// dates, data buffers, etc. This ensures that subsequent changes to either the original or the copy don't violate 
// the encapsulation of the owning object.

- (NSUInteger)apple_identifier {
    return apple_identifier;
}

- (NSString *)title {
    return title;
}

- (void)setTitle:(NSString *)aString {
    if ((!title && !aString) || (title && aString && [title isEqualToString:aString])) return;
    dirty = YES;
    [title release];
    title = [aString copy];
}

- (NSString *)company_name {
    return company_name;
}

- (void)setCompany_name:(NSString *)aString {
    if ((!company_name && !aString) || (company_name && aString && [company_name isEqualToString:aString])) return;
    dirty = YES;
    [company_name release];
    company_name = [aString copy];
}

- (NSString *)vendor_identifier {
    return vendor_identifier;
}

- (void)setVendor_identifier:(NSString *)aString {
    if ((!vendor_identifier && !aString) || (vendor_identifier && aString && [vendor_identifier isEqualToString:aString])) return;
    dirty = YES;
    [vendor_identifier release];
    vendor_identifier = [aString copy];
}

- (NSNumber *) identifierAsNumber
{
	return [NSNumber numberWithInt:apple_identifier];
}

#pragma mark Sorting
- (NSComparisonResult)compareBySales:(Product *)otherProduct
{
	if (self.totalRoyalties < otherProduct.totalRoyalties)
	{
		return NSOrderedDescending;
	}
	
	if (self.totalRoyalties > otherProduct.totalRoyalties)
	{
		return NSOrderedAscending;
	}
	
	return [self.title compare:otherProduct.title];  // if sales equal (maybe 0), sort by name
	//return NSOrderedSame;
}	

#pragma mark Notifications
- (void) updateTotalsFromDict:(NSDictionary *)totalsDict
{
	NSLog(@"%@", totalsDict);
	NSDictionary *tmpDict = [totalsDict objectForKey:@"ByApp"];
	
	NSDictionary *appDict = [tmpDict objectForKey:[self identifierAsNumber]];
	
	totalUnitsSold = [[appDict objectForKey:@"UnitsPaid"] intValue];
	totalUnitsFree = [[appDict objectForKey:@"UnitsFree"] intValue];
	
	sumsByCurrency = [[appDict objectForKey:@"SumsByCurrency"] retain];
	totalRoyalties = [[YahooFinance sharedInstance] convertToEuroFromDictionary:sumsByCurrency];
	
}

@end

