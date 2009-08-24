//
//  App.m
//  ASiST
//
//  Created by Oliver Drobnik on 20.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "App.h"
#import "ImageManipulator.h"
#import "ImageResizing.h"
#import "ASiSTAppDelegate.h"


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

@implementation App

@synthesize iconImage, iconImageNano, isNew, averageRoyaltiesPerDay, apple_identifier, totalRoyalties, totalUnitsSold;


- (id)init
{
	// default images
	if (self = [super init])
	{
		self.iconImage = [UIImage imageNamed:@"Empty.png"];
		UIImage *tmpImageNanoResized = [self.iconImage scaleImageToSize:CGSizeMake(32.0,32.0)];
		self.iconImageNano = tmpImageNanoResized;
		
		// subscribe to total update notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTotalsUpdated:) name:@"AppTotalsUpdated" object:nil];
	}
	
	return self;
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
	
	[self loadImageFromBirne];
	
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
		
		[self insertIntoDatabase:database];
		[self loadImageFromBirne];

		return self;
	}
	else
	{
		return nil;
	}
	
}

- (void) loadImageFromBirne
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", apple_identifier]];
	
	UIImage *tmpImage = [UIImage imageWithContentsOfFile:path];
	
	if (tmpImage)
	{
		self.iconImage = tmpImage;
		UIImage *tmpImageNanoResized = [tmpImage scaleImageToSize:CGSizeMake(32.0,32.0)];
		self.iconImageNano = tmpImageNanoResized;

		return;
	}
	
	NSString *URL=[NSString stringWithFormat:@"http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%d&amp;mt=8", apple_identifier];
	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:600.0];
	theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
	if (theConnection) 
	{
		
		// Create the NSMutableData that will hold
		// the received data
		// receivedData is declared as a method instance elsewhere
		if (!receivedData)
		{
			receivedData=[[NSMutableData data] retain];
		}
	}
	else
	{
		// inform the user that the download could not be made
	}
	
	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    //[connection release]; is autoreleased
    // receivedData is declared as a method instance elsewhere
    [receivedData release];
	receivedData = nil;
	
 	
   // NSLog(@"Connection failed! Error - %@ %@",
   //       [error localizedDescription],
   //       [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	
	/*	if (myDelegate && [myDelegate respondsToSelector:@selector(sendingDone:)]) {
	 (void) [myDelegate performSelector:@selector(sendingDone:) 
	 withObject:self];
	 }
	 */	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	//NSString *URL;
	NSMutableURLRequest *theRequest;
	
	
	NSString *sourceSt = [[NSString alloc] initWithBytes:[receivedData bytes] length:[receivedData length] encoding:NSUTF8StringEncoding];
	if ([sourceSt hasPrefix:@"<"])
	{	// HTML
		NSRange range = [sourceSt rangeOfString:@"<iTunes>"];
		if (range.location!=NSNotFound)
		{
			NSRange BirneRange = [sourceSt rangeOfString:@"</iTunes>" options:NSLiteralSearch range:NSMakeRange(range.location+range.length, 100)];

			NSRange tempRange = NSMakeRange(range.location + range.length, BirneRange.location - range.location - range.length);
				
			
			NSString *UTF8Name = [[sourceSt substringWithRange:tempRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
			// if the title is different then we prefer the one from Birne
			if (![self.title isEqualToString:UTF8Name])
			{
				
				self.title = UTF8Name;
				[self updateInDatabase];
			}
		
		}
		
		range = [sourceSt rangeOfString:@"100x100-75.jpg"];
	
		if (range.location!=NSNotFound)
		{
			NSRange httpRange = [sourceSt rangeOfString:@"http://" options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
			NSString *imgURL = [sourceSt substringWithRange:NSMakeRange(httpRange.location, range.location - httpRange.location + range.length)];
			//NSLog(@"Got Icon URL: %@", imgURL);
		
		
			[receivedData setLength:0];
			theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:imgURL]
										   cachePolicy:NSURLRequestUseProtocolCachePolicy
									   timeoutInterval:600.0];
		
	
			theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
		}
	}
	else
	{   // JPG
		UIImage *tmpImage = [[UIImage alloc] initWithData:receivedData];
		UIImage *tmpImageRounded = [ImageManipulator makeRoundCornerImage:tmpImage cornerWidth:20 cornerHeight:20];
		UIImage *tmpImageResized = [tmpImageRounded scaleImageToSize:CGSizeMake(57.0,57.0)];
		self.iconImage = tmpImageResized;
		
		UIImage *tmpImageNanoResized = [tmpImageRounded scaleImageToSize:CGSizeMake(32.0,32.0)];
		self.iconImageNano = tmpImageNanoResized;

		
		NSData *tmpData = UIImagePNGRepresentation (tmpImageResized);
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", apple_identifier]];
		
		[tmpData writeToFile:path atomically:YES];
	//	NSLog(@"Written Icon to %@", path);

	//	tmpData = UIImagePNGRepresentation (tmpImageNanoResized);
	//	path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d_small.png", apple_identifier]];
	//	[tmpData writeToFile:path atomically:YES];
	//	NSLog(@"Written Nano Icon to %@", path);

		//[tmpImage release];
		
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		[[[appDelegate appViewController] tableView] reloadData];
		

		
		
	}
}

- (void)dealloc 
{
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[iconImage release];
	[title release];
	[vendor_identifier release];
    [company_name release];
    [super dealloc];
}

- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
    // This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO app(id, title, vendor_identifier, company_name) VALUES(?, ?, ?, ?)";
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

- (void)deleteFromDatabase {
    // Compile the delete statement if needed.
    if (delete_statement == nil) {
        const char *sql = "DELETE FROM app WHERE id=?";
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
        const char *sql = "UPDATE app set title = ? WHERE id=?";
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
        NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
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

#pragma mark Sorting
- (NSComparisonResult)compareBySales:(App *)otherApp
{
	if (self.averageRoyaltiesPerDay < otherApp.averageRoyaltiesPerDay)
	{
		return NSOrderedDescending;
	}
	
	if (self.averageRoyaltiesPerDay > otherApp.averageRoyaltiesPerDay)
	{
		return NSOrderedAscending;
	}
	
	return [self.title compare:otherApp.title];  // if sales equal (maybe 0), sort by name
	//return NSOrderedSame;
}	

#pragma mark Notifications
- (void)appTotalsUpdated:(NSNotification *) notification
{
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		
		NSDictionary *appDict = [tmpDict objectForKey:[NSNumber numberWithInt:apple_identifier]];
		
		totalRoyalties = [[appDict objectForKey:@"Royalties"] doubleValue];
		totalUnitsSold = [[appDict objectForKey:@"Units"] intValue];
	} 
}


@end
