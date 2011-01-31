//
//  App.m
//  ASiST
//
//  Created by Oliver Drobnik on 20.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "App.h"
#import "InAppPurchase.h"
#import "UIImage+Helpers.h"
#import "NSString+Helpers.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
#import "ReviewDownloaderOperation.h"
#import "Review_v1.h"
#import "Database.h"
#import "Country_v1.h"
#import "Report_v1.h"
#import "SynchingManager.h"
#import "DDData.h"


// Static variables for compiled SQL queries. This implementation choice is to be able to share a one time
// compilation of each query across all instances of the class. Each time a query is used, variables may be bound
// to it, it will be "stepped", and then reset for the next usage. When the application begins to terminate,
// a class method will be invoked to "finalize" (delete) the compiled queries - this must happen before the database
// can be closed.
static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *delete_statement = nil;
static sqlite3_stmt *update_statement = nil;
static sqlite3_stmt *reviews_statement = nil;

//static sqlite3_stmt *delete_points_statement = nil;

//static sqlite3_stmt *hydrate_statement = nil;
//static sqlite3_stmt *dehydrate_statement = nil;

// Date formatter for XML files
static NSDateFormatter *dateFormatterToRead = nil;


@implementation App

@synthesize iconImage, iconImageNano;
@synthesize reviews, countNewReviews;
@synthesize lastReviewRefresh;



- (id)init
{
	// default images
	if (self = [super init])
	{
		self.iconImage = [UIImage imageNamed:@"Empty.png"];
		UIImage *tmpImageNanoResized = [self.iconImage scaleImageToSize:CGSizeMake(32.0,32.0)];
		self.iconImageNano = tmpImageNanoResized;
		
		
		// subscribe to total update notifications
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTotalsUpdated:) name:@"AppTotalsUpdated" object:nil];
		// subscribe to cache emptying
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyCache:) name:@"EmptyCache" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:@"UIApplicationWillTerminateNotification" object:nil];
		
	}
	
	return self;
}

- (void)dealloc 
{
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[sumsByCurrency release];
	[iconImage release];
	[iconImageNano release];
	[title release];
	[vendor_identifier release];
    [company_name release];
	
	[reviews release];
	[reviewsByNameVersion release];
    [super dealloc];
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
		
		
		// review loading deferred
		
		
    }
	
	[self loadImageFromBirne];
	//[self loadSumsFromCache];
	
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
		[self loadImageFromBirne];
		
		return self;
	}
	else
	{
		return nil;
	}
	
}

#pragma mark Loading Icon 
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
	[theRequest addValue:@"iTunes/9.0.2" forHTTPHeaderField:@"User-Agent"];
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
}



- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	//NSString *URL;
	NSMutableURLRequest *theRequest;
	
	
	NSString *sourceSt = [[[NSString alloc] initWithBytes:[receivedData bytes] length:[receivedData length] encoding:NSUTF8StringEncoding] autorelease];
	if ([sourceSt hasPrefix:@"<"])
	{	// HTML
		NSRange range = [sourceSt rangeOfString:@"<iTunes>"];
		if (range.location!=NSNotFound)
		{
			NSRange BirneRange = [sourceSt rangeOfString:@"</iTunes>" options:NSLiteralSearch range:NSMakeRange(range.location+range.length, 1000)];
			
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
		UIImage *tmpImage = [UIImage imageWithData:receivedData];
		
		// use original iTunes mask
		UIImage *mask = [UIImage imageNamed:@"cover_mask_rounded_100x100.png"];
		UIImage *tmpImageRounded = [tmpImage imageByMaskingWithImage:mask];
		
		//UIImage *tmpImageRounded = [ImageManipulator makeRoundCornerImage:tmpImage cornerWidth:20 cornerHeight:20];
		
		UIImage *tmpImageResized = [tmpImageRounded scaleImageToSize:CGSizeMake(56.0,56.0)];
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

#pragma mark Database

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
	
	NSAssert2((success == SQLITE_OK) || (success >= SQLITE_ROW), @"Error: sqlite3_step failed with error %d (%s).", success, sqlite3_errmsg(database));
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
        NSAssert1(0, @"Error: failed to update in database with message '%s'.", sqlite3_errmsg(database));
    }
}

#pragma mark Properties
- (NSDate *)lastReviewRefresh
{
	if (!lastReviewRefresh)
	{
		// get from user defaults
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		lastReviewRefresh = [defaults objectForKey:[NSString stringWithFormat:@"ReviewsLoaded_%d", apple_identifier]];
	}
	
	return lastReviewRefresh;
}

- (void)setLastReviewRefresh:(NSDate *)newDate
{
	if (lastReviewRefresh!=newDate)
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:newDate forKey:[NSString stringWithFormat:@"ReviewsLoaded_%d", apple_identifier]];
		
		[lastReviewRefresh release];
		lastReviewRefresh = [newDate retain];
	}
}

- (void)addReview:(Review_v1 *)newReview
{
	[reviews addObject:newReview];
	[reviewsByNameVersion setObject:newReview forKey:[newReview compoundKey]];
}

- (void)sendReviewUpdateNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AppReviewsUpdated" object:nil userInfo:(id)self];
}

- (void)backgroundLoadReviewsFromStubs:(NSArray *)lines
{
	stagedLoadInProgress = YES;
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	int i=0;
	
	for (NSString *oneLine in lines)
	{
		Review_v1 *decodedReview = [[Review_v1 alloc] initWithString:oneLine];
		
		if (decodedReview)
		{
			decodedReview.app = self;
			decodedReview.database = database;
			[self performSelectorOnMainThread:@selector(addReview:) withObject:decodedReview waitUntilDone:YES];
			i++;
			[decodedReview release];
		}
	}
	
	if (i)
	{
		[self performSelectorOnMainThread:@selector(sendReviewUpdateNotification) withObject:nil waitUntilDone:YES];
	}

	stagedLoadInProgress = NO;
	[pool release];
}

- (NSMutableArray *)reviewsInStages:(BOOL)loadReviewsInStages
{
	// if we already have reviews we ignore the parameter
	if (!reviews)
	{
		reviews = [[NSMutableArray array] retain];
		reviewsByNameVersion = [[NSMutableDictionary dictionary] retain];
		
		// load what's in the DB for this app
		
		// try cache first
		
		NSString *path = [NSString pathForFileInDocuments:[NSString stringWithFormat:@"review_cache_%d.dat", apple_identifier]];
		NSData *compressed = [NSData dataWithContentsOfFile:path];
		
		if (compressed)
		{
			NSData *data = [compressed gzipInflate];
			
			NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
			NSArray *lines = [string componentsSeparatedByString:@"\n\r\n"];
			
			int i=0;
			for (NSString *oneLine in lines)
			{
				if (!(loadReviewsInStages&&i>=10))
				{
					Review_v1 *decodedReview = [[Review_v1 alloc] initWithString:oneLine];
					
					if (decodedReview)
					{
						decodedReview.app = self;
						decodedReview.database = database;
						[self addReview:decodedReview];
						i++;
						[decodedReview release];
					}
				}
			}
			
			if (loadReviewsInStages&&(i>=10))
			{
				NSRange range = NSMakeRange(i, [lines count]-i);
				
				if (range.length)
				{
					// load the rest
					NSArray *rest = [lines subarrayWithRange:range];
					
					[self performSelectorInBackground:@selector(backgroundLoadReviewsFromStubs:) withObject:rest];
				}
				
			}
			
			return reviews;
		}
		
		if (reviews_statement == nil) 
		{
			// Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
			// This is a great way to optimize because frequently used queries can be compiled once, then with each
			// use new variable values can be bound to placeholders.
			const char *sql = "SELECT id FROM review WHERE app_id=?";
			if (sqlite3_prepare_v2(database, sql, -1, &reviews_statement, NULL) != SQLITE_OK) {
				NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
			}
		}
		// For this query, we bind the primary key to the first (and only) placeholder in the statement.
		// Note that the parameters are numbered from 1, not from 0.
		sqlite3_bind_int(reviews_statement, 1, apple_identifier);
		
		while ((sqlite3_step(reviews_statement) == SQLITE_ROW)) // (!(loadReviewsInStages&&i>100))&&
		{
			NSUInteger review_id = sqlite3_column_int(reviews_statement, 0);
			
			Review_v1 *loadedReview = [[Review_v1 alloc] initWithPrimaryKey:review_id database:database];
			
			if (loadedReview)
			{
				loadedReview.app = self;
			
				[self addReview:loadedReview];
				[loadedReview release];
			}
		}
		// Reset the statement for future reuse.
		sqlite3_reset(reviews_statement);
	}
	
	return reviews;
}

- (NSMutableArray *)reviews
{
	return [self reviewsInStages:NO];
}

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

- (UIImage *)iconImage
{
	if (iconImage)
	{
		return iconImage;
	}
	else
	{
		return [UIImage imageNamed:@"Empty.png"];
	}
}

- (UIImage *)iconImageNano
{
	if (iconImageNano)
	{
		return iconImageNano;
	}
	else
	{
		return [UIImage imageNamed:@"EmptyNano.png"];
	}
}

- (NSArray *)inAppPurchases
{
	return [DB iapsForApp:self];
}


// override to include IAPs
-(double) totalRoyalties
{
	double ret = super.totalRoyalties;
	
	for (InAppPurchase *oneIAP in [self inAppPurchases])
	{
		ret += oneIAP.totalRoyalties;
	}
	
	return ret;
}

/*
 // override to include IAPs
 -(double) averageRoyaltiesPerDay
 {
 double ret = averageRoyaltiesPerDay;
 double i = 1;
 
 for (InAppPurchase *oneIAP in [self inAppPurchases])
 {
 ret += oneIAP.averageRoyaltiesPerDay;
 i++;
 }
 
 return ret/i;
 }
 */


// override to include IAPs
-(NSInteger) totalUnits
{
	double ret = super.totalUnits;
	
	for (InAppPurchase *oneIAP in [self inAppPurchases])
	{
		ret += oneIAP.totalUnits;
	}
	
	return ret;
}

- (double) averageRoyaltiesPerDay
{
	double sum = 0;
	
	if (!averageRoyaltiesPerDay)
	{
		NSArray *sortedReports = [DB sortedReportsOfType:ReportTypeDay];
		
		NSInteger reportsToAvg = MIN(7,[sortedReports count]);
		
		for (int i=0; i<reportsToAvg; i++)
		{
			Report_v1 *report = [sortedReports objectAtIndex:i];
			
			double appRoyalites = [report sumRoyaltiesForProduct:self transactionType:TransactionTypeSale];  // in EUR
			double iapRoyalites = [report sumRoyaltiesForInAppPurchasesOfApp:self];  // in EUR
			
			sum += appRoyalites + iapRoyalites;
		}
		
		if (reportsToAvg>0)
		{
			averageRoyaltiesPerDay = sum / (double)reportsToAvg;
		}
		
	}
	
	return averageRoyaltiesPerDay;
}




- (void)emptyCache:(NSNotification *) notification
{
	[super emptyCache:notification];
	[reviews release];
	reviews = nil;
	[iconImage release];
	iconImage = nil;
	[iconImageNano release];
	iconImageNano = nil;
}

#pragma mark ReviewScraper

- (Review_v1 *)reviewExists:(Review_v1 *)searchReview
{
	return [reviewsByNameVersion objectForKey:[searchReview compoundKey]];
}


- (void) didFinishRetrievingReviews:(NSArray *)scrapedReviews;
{
	BOOL modifiedReviews = NO;
	for (Review_v1 *oneReview in scrapedReviews)
	{
		Review_v1 *existingReview = [self reviewExists:oneReview];
		
		if (existingReview)
		{
			BOOL textChanged = ![oneReview.review isEqualToString:existingReview.review];
			BOOL starsChanged = (((int)(oneReview.stars*5.0))!=((int)(existingReview.stars*5.0)));
			
			if (textChanged||starsChanged)
			{
				if (textChanged)
				{
					existingReview.review = oneReview.review;
					existingReview.translated_review = nil;
					[[SynchingManager sharedInstance]translateReview:existingReview delegate:existingReview];
				}
				
				if (starsChanged)
				{
					existingReview.stars = oneReview.stars;
				}
				
				[existingReview updateDatabase];
				existingReview.isNew = YES;
				countNewReviews ++;
				modifiedReviews = YES;
				existingReview.country.usedInReport = YES; // loads icon if we don't have it yet
			}
		}
		else
		{
			[oneReview insertIntoDatabase:database];
			if (oneReview.isNew)
			{
				countNewReviews++;
				modifiedReviews = YES;
				oneReview.country.usedInReport = YES; // loads icon if we don't have it yet
				[self addReview:oneReview];
				
				[[SynchingManager sharedInstance]translateReview:oneReview delegate:oneReview];
				
			}
		}
	}
	
	if (modifiedReviews)
	{
		//[self.reviews release];
	
		//reviews = [[tmpArray sortedArrayUsingSelector:@selector(compareByReviewDate:)] retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AppReviewsUpdated" object:nil userInfo:(id)self];
	}
	
	self.lastReviewRefresh = [NSDate date];
}

- (void) removeReviewTranslations
{
	for (Review_v1 *oneReview in self.reviews)
	{
		oneReview.translated_review = nil;
		//[oneReview updateDatabase]; // unnecessary
		
		[[SynchingManager sharedInstance] translateReview:oneReview delegate:oneReview];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"AppReviewsUpdated" object:nil userInfo:(id)self];
}

- (void) getAllReviews
{
	
	NSMutableDictionary *countries = [[Database sharedInstance] countries];
	NSArray *allKeys = [countries allKeys];
	
	for (NSString *oneKey in allKeys)
	{
		Country_v1 *oneCountry = [countries objectForKey:oneKey];
		if (oneCountry.appStoreID)
		{
			[[SynchingManager sharedInstance] scrapeForApp:self country:oneCountry delegate:self];
		}
	}
}

- (NSString *) reviewsAsHTML
{
	NSMutableString *tmpString = [NSMutableString string];
	
	for (Review_v1 *oneReview in self.reviews)
	{
		[tmpString appendString:[oneReview stringAsHTML]];
	}
	
	if ([tmpString length])
	{
		return [NSString stringWithString:tmpString];
	}
	else 
	{
		return @"<p>No reviews in Database</p>";
	}
}

#pragma mark Caching
-(void)cacheReviewsIfLoaded
{
	if (!reviews) return;
	
	NSMutableString *tmpStr = [NSMutableString string];
	
	// we cache them in the same order the view display it
	NSArray *sortedReviews = [reviews sortedArrayUsingSelector:@selector(compareByReviewDate:)];
	
	for (Review_v1 *oneReview in sortedReviews)
	{
		NSString *stub = [oneReview encodedAsString];
		
		[tmpStr appendFormat:@"%@\n\r\n", stub];
	}
	
	NSString *path = [NSString pathForFileInDocuments:[NSString stringWithFormat:@"review_cache_%d.dat", apple_identifier]];
	NSData *data = [tmpStr dataUsingEncoding:NSUTF8StringEncoding];
	NSData *compressed = [data gzipDeflate];
	[compressed writeToFile:path atomically:YES];
}


-(void)applicationWillTerminate:(NSNotification *)notification
{
	[self cacheReviewsIfLoaded];
	[reviews release];  // prevent caching a second time
	reviews = nil;
}
@end
