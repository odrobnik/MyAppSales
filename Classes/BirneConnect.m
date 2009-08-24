//
//  BirneConnect.m
//  ASiST
//
//  Created by Oliver Drobnik on 19.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "BirneConnect.h"
#import "BirneConnect+Totals.h"
#import "YahooFinance.h"
#import "DDData.h"
#import "ASiSTAppDelegate.h"

#import "App.h"
#import "Report.h"
#import "Country.h"

#import "ZipArchive.h"
#import "NSString+Helpers.h"


// Static variables for compiled SQL queries. This implementation choice is to be able to share a one time
// compilation of each query across all instances of the class. Each time a query is used, variables may be bound
// to it, it will be "stepped", and then reset for the next usage. When the application begins to terminate,
// a class method will be invoked to "finalize" (delete) the compiled queries - this must happen before the database
// can be closed.
//static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *insert_statement_sale = nil;
static sqlite3_stmt *reportid_statement = nil;
//static sqlite3_stmt *insertreport_statement = nil;

// private methods
@interface BirneConnect ()
- (BOOL) shouldAutoSync;
@end






@implementation BirneConnect

@synthesize apps, reports, reportsByType, latestReportsByType, countries, username, password, lastSuccessfulLoginTime, database;
@synthesize myYahoo, dataToImport;

- (id) init
{
	newApps = 0;
	newReports = 0;
	newReportsByType = [[NSMutableDictionary alloc] init];
	syncing = NO;
	dataToImport = nil;

	
	if (self = [super init])
	{
		// set up local indexes
		reportsDaily = [[NSMutableArray alloc] init];
		reportsWeekly = [[NSMutableArray alloc] init];
		reportsByType = [[NSMutableArray alloc] initWithObjects:reportsDaily, reportsWeekly, nil];
		
		latestReportsByType = [[NSMutableDictionary alloc] init];

		
		// connect with database
		[self createEditableCopyOfDatabaseIfNeeded];
		[self initializeDatabase];
		[self loadCountryList];
		[self getTotals];
		
		// subscribe to change of exchange rates
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeRatesChanged:) name:@"ExchangeRatesChanged" object:nil];

		
		[self setStatus:@"Updating Currency Exchange Rates"];
		self.myYahoo = [YahooFinance sharedInstance]; 
		[self setStatus:nil];

		[self refreshIndexes];
		//[self calcAvgRoyaltiesForApps];  done at end of refresh
		
		return self;
	}
	return nil;
}

- (id) initWithLogin:(NSString *)user password:(NSString *)pass
{
	if (self = [self init])
	{
		self.username = user;
		self.password = pass;

		// only auto-sync if we did not already download a daily report today
		if ([self shouldAutoSync])
		{
			[self loginAndSync];
		}
		
		return self;
	}
	return nil;
}

- (void) sync
{
	// only synch if we are not already doing so
	if (syncing)
	{
		return;
	}
	
	syncing = YES;
	
	if (loginPostURL&&![loginPostURL isEqualToString:@""])
	{
		[self toggleNetworkIndicator:YES];

		loginStep = 3;
		[receivedData setLength:0];

		NSMutableURLRequest *theRequest;
		theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:loginPostURL]
									   cachePolicy:NSURLRequestUseProtocolCachePolicy
								   timeoutInterval:30.0];
		[theRequest setHTTPMethod:@"POST"];
		[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
		//create the body
		NSMutableData *postBody = [NSMutableData data];
		[postBody appendData:[@"11.7=Summary&11.9=Daily&hiddenDayOrWeekSelection=Daily&hiddenSubmitTypeName=ShowDropDown" dataUsingEncoding:NSUTF8StringEncoding]];
		[theRequest setHTTPBody:postBody];
	
		theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
		[self setStatus:@"Retrieving Day Options"];
	}
	else
	{
		[self loginAndSync];
	}
}



- (void) loginAndSync
{
	//[self importReportsFromDocumentsFolder];
	//return self;
	
	if (!(self.username&&self.password&&![username isEqualToString:@""]&&![password isEqualToString:@""]))
	{
		//[self setStatus:@"Username or password empty!"];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome to My App Sales" message:@"To start downloading your reports please enter your login information.\nSales/Trend reports are for directional purposes only, do not use for financial statement purpose. Money amounts may vary due to changes in exchange rates." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate.tabBarController setSelectedIndex:3];
		return;
	}
	
	syncing = YES;
	
	// open login page
	loginStep = 0;
	NSString *URL=[NSString stringWithFormat:@"https://itts.apple.com/cgi-bin/WebObjects/Piano.woa"];
	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:30.0];
	[self toggleNetworkIndicator:YES];
	[self setStatus:@"Opening HTTPS Connection"];
	
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

- (BOOL) shouldAutoSync
{
	// only auto-sync if we did not already download a daily report today
	Report *lastDailyReport = [latestReportsByType objectForKey:[NSNumber numberWithInt:ReportTypeDay]];
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	
	NSDateComponents *lastComps = [gregorian components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:lastDailyReport.downloadedDate];
	NSDateComponents *todayComps = [gregorian components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[NSDate date]];
	
	return !((lastComps.day == todayComps.day)&&(lastComps.month == todayComps.month)&&(lastComps.year == todayComps.year));
	}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[dataToImport release];
	[myYahoo release];
	[lastSuccessfulLoginTime release];
	[latestReportsByType release];
	[reportsByType release];

	[countries release];
	[dateFormatterToRead release];
	[apps release];
	[reports release];
	[weekOptions release];
	[dayOptions release];
	[loginPostURL release];
	[receivedData release];
	[super dealloc];
}

#pragma mark Initialization

- (void) loadCountryList
{
	if (!countries)
	{
		countries = [[NSMutableDictionary alloc] init];
	}
	sqlite3_stmt *statement = nil;
	
	// we load all countries, because the country icon is only loaded if it is usedInReport
	const char *sql = "SELECT iso3 from country";
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	
	while (sqlite3_step(statement) == SQLITE_ROW) 
	{
		NSString *cntry = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
		Country *tmpCountry = [[Country alloc] initWithISO3:cntry database:database];
		[countries setObject:tmpCountry forKey:tmpCountry.iso2];
		[tmpCountry release];
	} 
	
	// Finalize the statement, no reuse.
	sqlite3_finalize(statement);
}

- (NSArray *) salesCurrencies
{
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
	
	sqlite3_stmt *statement = nil;
	const char *sql = "SELECT distinct customer_currency from sale";
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		
	}
	
	while (sqlite3_step(statement) == SQLITE_ROW) 
	{
		NSString *currency = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
		[tmpArray addObject:currency];
	} 
	
	// Finalize the statement, no reuse.
	sqlite3_finalize(statement);
	
	NSArray *retArray = [NSArray arrayWithArray:tmpArray];
	[tmpArray release];
	
	return retArray;
}

#pragma mark HTTP call back methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere
    [receivedData setLength:0];
//	NSLog(@"%d %@", [response statusCode], [[response allHeaderFields] objectForKey:@"Content-Type"]);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self toggleNetworkIndicator:NO];
    // release the connection, and the data object
    //[connection release]; is autoreleased
    // receivedData is declared as a method instance elsewhere
    [receivedData release];
	receivedData = nil;
	
	[self setStatus:[error localizedDescription]];
	[self setStatus:nil];
	syncing = NO;

  //  NSLog(@"Connection failed! Error - %@ %@",
  //        [error localizedDescription],
  //        [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	
	/*	if (myDelegate && [myDelegate respondsToSelector:@selector(sendingDone:)]) {
	 (void) [myDelegate performSelector:@selector(sendingDone:) 
	 withObject:self];
	 }
	 */	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *URL;
	NSMutableURLRequest *theRequest;
	NSMutableData *postBody;
	

	
	NSString *sourceSt = [[[NSString alloc] initWithBytes:[receivedData bytes] length:[receivedData length] encoding:NSASCIIStringEncoding] autorelease];
	//NSLog(sourceSt);
	
	switch (loginStep) {
		case 0:   // open Login page
		{
			// search for outer post url
			NSRange formRange = [sourceSt rangeOfString:@"<form method=\"post\" action=\""];
			
			if (formRange.location!=NSNotFound)
			{
				NSRange quoteRange = [sourceSt rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(formRange.location+formRange.length, 100)];
				if (quoteRange.length)
				{
					URL = [@"https://itts.apple.com" stringByAppendingString:[sourceSt substringWithRange:NSMakeRange(formRange.location+formRange.length, quoteRange.location-formRange.location-formRange.length)]];
					loginStep = 1;
					[receivedData setLength:0];
					theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
																			cachePolicy:NSURLRequestUseProtocolCachePolicy
																		timeoutInterval:30.0];
					
					[theRequest setHTTPMethod:@"POST"];
					[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
					
					//create the body
					postBody = [NSMutableData data];
					[postBody appendData:[[NSString stringWithFormat:@"theAccountName=%@&theAccountPW=%@&1.Continue.x=20&1.Continue.y=6&theAuxValue=", 
										  [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
										   [password stringByUrlEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
					[theRequest setHTTPBody:postBody];
					
					theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
					[self setStatus:@"Sending Login Information"];
				}
			}
			
			
			break;
		}
		case 1: // Received Answer to Login
		{
			// search for frmVendorPage URL
			NSRange formRange = [sourceSt rangeOfString:@"<form method=\"post\" name=\"frmVendorPage\" action=\""];
			
			if (formRange.location!=NSNotFound)
			{
				// found the string, now find it's end
				NSRange quoteRange = [sourceSt rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(formRange.location+formRange.length, 100)];
				if (quoteRange.length==1)
				{
					self.lastSuccessfulLoginTime = [NSDate date];
					URL = [@"https://itts.apple.com" stringByAppendingString:[sourceSt substringWithRange:NSMakeRange(formRange.location+formRange.length, quoteRange.location-formRange.location-formRange.length)]];

					loginStep = 2;
					
					[receivedData setLength:0];
					
					theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
																			cachePolicy:NSURLRequestUseProtocolCachePolicy
																		timeoutInterval:30.0];
					
					[theRequest setHTTPMethod:@"POST"];
					[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
					
					//create the body
					postBody = [NSMutableData data];
					[postBody appendData:[@"11.7=Summary&11.9=Daily&hiddenDayOrWeekSelection=Daily&hiddenSubmitTypeName=ShowDropDown" dataUsingEncoding:NSUTF8StringEncoding]];
					
					//add the body to the post
					[theRequest setHTTPBody:postBody];
					
					theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
					[self setStatus:@"Retrieving Day Options"];
					
				}
				else
				{
					loginPostURL = @"";
					syncing = NO;
				}
			}
			else
			{
				// Login Failed
				loginPostURL = @"";
				syncing = NO;
				[self toggleNetworkIndicator:NO];
				self.lastSuccessfulLoginTime = nil;

				UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Login Failed"
																 message:@"Your login or password was entered incorrectly."
																delegate:self
													   cancelButtonTitle:@"Ok"
													   otherButtonTitles:nil, nil];
				[alert show];
				[alert release];
				[self setStatus:nil];
				
			}
			break;
		}
		case 2:  // select Day
		{
			// search for frmVendorPage URL
			NSRange formRange = [sourceSt rangeOfString:@"<form method=\"post\" name=\"frmVendorPage\" action=\""];
			
			if (formRange.location!=NSNotFound)
			{
				// found the string, now find it's end
				NSRange quoteRange = [sourceSt rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(formRange.location+formRange.length, 100)];
				if (quoteRange.length==1)
				{
					URL = [@"https://itts.apple.com" stringByAppendingString:[sourceSt substringWithRange:NSMakeRange(formRange.location+formRange.length, quoteRange.location-formRange.location-formRange.length)]];

					
					loginStep = 3;
					[receivedData setLength:0];
					theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
																			cachePolicy:NSURLRequestUseProtocolCachePolicy
																		timeoutInterval:30.0];
					[theRequest setHTTPMethod:@"POST"];
					[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
					
					//create the body
					NSMutableData *postBody = [NSMutableData data];
					[postBody appendData:[@"11.7=Summary&11.9=Daily&hiddenDayOrWeekSelection=Daily&hiddenSubmitTypeName=ShowDropDown" dataUsingEncoding:NSUTF8StringEncoding]];
					[theRequest setHTTPBody:postBody];
					
					theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
					[self setStatus:@"Retrieving Day Options"];
				}
			}
			else
			{
				loginPostURL = @"";
				syncing = NO;
				[self toggleNetworkIndicator:NO];
				
			}
			break;
		}
		case 3:
		{
			// search for frmVendorPage URL
			NSRange formRange = [sourceSt rangeOfString:@"<form method=\"post\" name=\"frmVendorPage\" action=\""];
			
			if (formRange.location!=NSNotFound)
			{
				// found the string, now find it's end
				NSRange quoteRange = [sourceSt rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(formRange.location+formRange.length, 100)];
				if (quoteRange.length==1)
				{
					URL = [@"https://itts.apple.com" stringByAppendingString:[sourceSt substringWithRange:NSMakeRange(formRange.location+formRange.length, quoteRange.location-formRange.location-formRange.length)]];
					
					loginPostURL = [[NSString alloc] initWithString:URL];
					loginStep = 4;
					
					
					NSRange selectRange = [sourceSt rangeOfString:@"<select Id=\"dayorweekdropdown\""];
					
					dayOptions = nil;
					if (selectRange.location!=NSNotFound)
					{
						NSRange endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:NSMakeRange(selectRange.location, 1000)];
						dayOptions = [[[sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)] optionsFromSelect] retain];
						dayOptionsIdx = 0;

						
						if (![self requestDailyReport])
						{
								loginStep = 5;
								
								[receivedData setLength:0];
								theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:loginPostURL]
																   cachePolicy:NSURLRequestUseProtocolCachePolicy
															   timeoutInterval:30.0];
								[theRequest setHTTPMethod:@"POST"];
								[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
								
								//create the body
								NSMutableData *postBody = [NSMutableData data];
								[postBody appendData:[@"11.7=Summary&11.9=Weekly&hiddenDayOrWeekSelection=Weekly&hiddenSubmitTypeName=ShowDropDown" dataUsingEncoding:NSUTF8StringEncoding]];
								[theRequest setHTTPBody:postBody];
								
								theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
								[self setStatus:@"Retrieving Week Options"];
								
							
						}
					}
				}
			}
			else
			{
				loginPostURL = @"";
				syncing = NO;
				[self toggleNetworkIndicator:NO];
			}
			break;
		}
		case 4:  // we should be getting day report data
		{
			if (![sourceSt hasPrefix:@"<"])
			{
				NSData *decompressed = [receivedData gzipInflate];
				NSString *decompStr = [[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSASCIIStringEncoding];
				
				[self addReportToDBfromString:decompStr];
				[self refreshIndexes];  // this causes avgRoyalties calc

				
				[decompStr release];
				
				if (![self requestDailyReport])
				{
					
					loginStep = 5;
					
					 [receivedData setLength:0];
					 theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:loginPostURL]
					 cachePolicy:NSURLRequestUseProtocolCachePolicy
					 timeoutInterval:30.0];
					 [theRequest setHTTPMethod:@"POST"];
					 [theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
					 
					 //create the body
					 NSMutableData *postBody = [NSMutableData data];
					 [postBody appendData:[@"11.7=Summary&11.9=Weekly&hiddenDayOrWeekSelection=Weekly&hiddenSubmitTypeName=ShowDropDown" dataUsingEncoding:NSUTF8StringEncoding]];
					 [theRequest setHTTPBody:postBody];
					 
					 theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
					[self setStatus:@"Retrieving Week Options"];
					
				}
			}
			break;
		}
			
			
		case 5:
		{
			loginStep = 6;
					NSRange selectRange = [sourceSt rangeOfString:@"<select Id=\"dayorweekdropdown\""];
					
					weekOptions = nil;
					if (selectRange.location!=NSNotFound)
					{
						NSRange endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:NSMakeRange(selectRange.location, 1000)];
						weekOptions = [[[sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)] optionsFromSelect] retain];
						weekOptionsIdx = 0;
						
						[self requestWeeklyReport];
						//[self syncReports];
					}
			break;
		}
			
		case 6:  // we should be getting week report data
		{
			if (![sourceSt hasPrefix:@"<"])
			{
				NSData *decompressed = [receivedData gzipInflate];
				NSString *decompStr = [[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSUTF8StringEncoding];
				
				[self addReportToDBfromString:decompStr];
				[self refreshIndexes];  // this causes avgRoyalties calc

				
				[decompStr release];
				
				[self requestWeeklyReport];
			}
			break;
		}
			
	/*	default:  // any other step means report data
		{
			if (![sourceSt hasPrefix:@"<"])
			{
				NSData *decompressed = [receivedData gzipInflate];
				NSString *decompStr = [[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSASCIIStringEncoding];
			
				[self addReportToDBfromString:decompStr forDay:[dayOptions objectAtIndex:dayOptionsIdx]];
			
				[decompStr release];
			
				[self syncReports];
			}
		}*/
	}
}

#pragma mark Status Indicators

- (void) setStatus:(NSString *)message
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"StatusMessage" object:nil userInfo:(id)message];
}

- (void) toggleNetworkIndicator:(BOOL)isON
{
	// forward to appDelegate
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[appDelegate toggleNetworkIndicator:isON];
}

- (void) insertAppNotification:(App *)app
{
	
	NSIndexPath *tmpIndex = [self indexforApp:app];
	
	NSArray *insertIndexPaths = [NSArray arrayWithObjects:
								 tmpIndex,
								 nil];
	
	NSArray *values = [NSArray arrayWithObjects:insertIndexPaths, app, [NSNumber numberWithInt:tmpIndex.row], [NSNumber numberWithInt:newApps], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"InsertIndexPaths", @"App", @"InsertionIndex", @"NewApps", nil];
	
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewAppAdded" object:nil userInfo:tmpDict];
}

- (void) insertReportNotification:(Report *)report
{
	
	NSIndexPath *tmpIndex = [self indexforReport:report];
	
	NSArray *insertIndexPaths = [NSArray arrayWithObjects:
								 tmpIndex,
								 nil];
	
	NSArray *values = [NSArray arrayWithObjects:insertIndexPaths, report, [NSNumber numberWithInt:tmpIndex.row], [NSNumber numberWithInt:newReports], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"InsertIndexPaths", @"Report", @"InsertionIndex", @"NewReports", nil];
	
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewReportAdded" object:nil userInfo:tmpDict];
	
	
	// local number of daily/weekly new Reports tracking
	NSNumber *typeKey = [NSNumber numberWithInt:report.reportType];
	NSNumber *theNum = [newReportsByType objectForKey:typeKey];
	if (!theNum)
	{
		theNum = [NSNumber numberWithInt:1];
		[newReportsByType setObject:theNum forKey:typeKey];
	}
	else
	{
		NSNumber *newNum = [NSNumber numberWithInt:[theNum intValue]+1];
		[newReportsByType setObject:newNum forKey:typeKey];
	}
	
}

#pragma mark Report Downloading

// look at dayOptions and request to download a report if not in DB
- (BOOL) requestDailyReport
{
	NSMutableURLRequest *theRequest;

	if ([dayOptions count]>dayOptionsIdx)
	{
		NSString *formDate = [[dayOptions objectAtIndex:dayOptionsIdx] stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
		if ([self reportIDForDate:[dayOptions objectAtIndex:dayOptionsIdx] type:ReportTypeDay])
		{
			// Already downloaded this day
			dayOptionsIdx++;
			return [self requestDailyReport];
		}
		[receivedData setLength:0];
		
		theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:loginPostURL]
										   cachePolicy:NSURLRequestUseProtocolCachePolicy
									   timeoutInterval:30.0];
		
		[theRequest setHTTPMethod:@"POST"];
		[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
		
		//create the body
		NSMutableData *postBody = [NSMutableData data];
		NSString *body = [NSString stringWithFormat:@"11.7=Summary&11.9=Daily&11.11.1=%@&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=Download", formDate, formDate];
		[postBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
		
		//add the body to the post
		[theRequest setHTTPBody:postBody];
		
		theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
		[self setStatus:[NSString stringWithFormat:@"Loading Day Report for %@", [dayOptions objectAtIndex:dayOptionsIdx]]];

		dayOptionsIdx ++;
		return YES;
	}
	else
	{
		[self refreshIndexes];   // because at this point we have all reports


		return NO;
	}
}

// look at dayOptions and request to download a report if not in DB
- (BOOL) requestWeeklyReport
{
	NSMutableURLRequest *theRequest;
	
	if ([weekOptions count]>weekOptionsIdx)
	{
		NSString *formDate = [[weekOptions objectAtIndex:weekOptionsIdx] stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
		if ([self reportIDForDate:[weekOptions objectAtIndex:weekOptionsIdx] type:ReportTypeWeek])
		{
			// Already downloaded this week
			weekOptionsIdx++;
			return [self requestWeeklyReport];
		}
		[receivedData setLength:0];
		
		theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:loginPostURL]
										   cachePolicy:NSURLRequestUseProtocolCachePolicy
									   timeoutInterval:30.0];
		
		[theRequest setHTTPMethod:@"POST"];
		[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
		
		//create the body
		NSMutableData *postBody = [NSMutableData data];
		NSString *body = [NSString stringWithFormat:@"11.7=Summary&11.9=Weekly&11.13.1=%@&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=Download", formDate, formDate];
		[postBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
		
		//add the body to the post
		[theRequest setHTTPBody:postBody];
		
		theConnection=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
		//NSLog(@"Step 4 - Request report for week %@", formDate);
		[self setStatus:[NSString stringWithFormat:@"Loading Week Report for %@", [weekOptions objectAtIndex:weekOptionsIdx]]];
		weekOptionsIdx++;
		
		return YES;
	}
	else
	{
		//NSLog(@"no more weeks");
		[self refreshIndexes];   // because at this point we have all reports
		
		[self toggleNetworkIndicator:NO];
		[self setStatus:@"Synchronization Done"];
		[self setStatus:nil];
		
		syncing = NO;
		
		// need to redo totals now
		[self getTotals];

		return NO;
	}
}

- (void) addReportToDBfromString:(NSString *)string;
{
	NSUInteger report_id=0;
	
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	NSEnumerator *enu = [lines objectEnumerator];
	NSString *oneLine;
	
	// first line = headers
	
	oneLine = [enu nextObject];
	NSArray *column_names = [oneLine componentsSeparatedByString:@"\t"];
	
	NSString *prev_until_date = @"";
	
	while(oneLine = [enu nextObject])
	{
		NSString *from_date = [oneLine getValueForNamedColumn:@"Begin Date" headerNames:column_names];
		NSString *until_date = [oneLine getValueForNamedColumn:@"End Date" headerNames:column_names];
		NSUInteger appID = [[oneLine getValueForNamedColumn:@"Apple Identifier" headerNames:column_names] intValue];
		NSString *vendor_identifier = [oneLine getValueForNamedColumn:@"Vendor Identifier" headerNames:column_names];
		NSString *company_name = [oneLine getValueForNamedColumn:@"Artist / Show" headerNames:column_names];
		NSString *title	= [oneLine getValueForNamedColumn:@"Title / Episode / Season" headerNames:column_names];
		NSUInteger type_id = [[oneLine getValueForNamedColumn:@"Product Type Identifier" headerNames:column_names] intValue];
		NSInteger units = [[oneLine getValueForNamedColumn:@"Units" headerNames:column_names] intValue];
		double royalty_price = [[oneLine getValueForNamedColumn:@"Royalty Price" headerNames:column_names] doubleValue];
		NSString *royalty_currency	= [oneLine getValueForNamedColumn:@"Royalty Currency" headerNames:column_names];
		double customer_price = [[oneLine getValueForNamedColumn:@"Customer Price" headerNames:column_names] doubleValue];
		NSString *customer_currency	= [oneLine getValueForNamedColumn:@"Customer Currency" headerNames:column_names];
		NSString *country_code	= [oneLine getValueForNamedColumn:@"Country Code" headerNames:column_names];
		
		if (from_date&&until_date&&appID&&vendor_identifier&&company_name&&title&&type_id&&units&&royalty_currency&&customer_currency&&country_code)
		{
			if ((!report_id)||(![prev_until_date isEqualToString:until_date]))   // added: possibly multiple different rows from different reports
			{  // detect report type from first line
				
				if ([from_date isEqualToString:until_date])
				{	// day report
					report_id=[self insertReportForDate:from_date UntilDate:until_date type:ReportTypeDay];
				}
				else
				{	// week report
					report_id=[self insertReportForDate:from_date UntilDate:until_date type:ReportTypeWeek];
				}
				
				if (!report_id)
				{
					//NSLog(@"Could not get a new report_id, probably already in DB");
					return;
				}
			}
			
			if (report_id)
			{
				NSNumber *app_key = [NSNumber numberWithInt:appID];
				if (![apps objectForKey:app_key])
				{
					App *app = [[App alloc] initWithTitle:title vendor_identifier:vendor_identifier apple_identifier:appID company_name:company_name database:database];
					newApps ++;
					
					[apps setObject:app forKey:app_key];
					[self insertAppNotification:app];
					[app release];
				}
				
				
				[self insertReportLineForAppID:appID type_id:type_id units:units royalty_price:royalty_price royalty_currency:royalty_currency customer_price:customer_price customer_currency:customer_currency country_code:country_code report_id:report_id];
			}
			
		}
		else
		{
			// lines that don't match the headers, most likey empty lines after the report
		} 
		
		prev_until_date = until_date;
	}
}

- (NSUInteger)insertReportForDate:(NSString *)from_date UntilDate:(NSString *)until_date type:(ReportType)type
{
	NSDate *tmp_from_date = [from_date dateFromString];
	
	
	NSDate *tmp_until_date = [until_date dateFromString];
	NSDate *tmp_downloaded_date = [NSDate date];
	
	
	if (!tmp_from_date || !tmp_until_date)
	{
		return 0;
	}
	
	if ([self reportIDForDate:until_date type:type])
	{
		//NSLog(@"Report for until_date %@ type %d already in DB", from_date, type);
		return 0;
	}
	
	
	NSUInteger primaryKey = 0;
	Report *tmp_report = [[Report alloc] initWithType:type from_date:tmp_from_date until_date:tmp_until_date downloaded_date:tmp_downloaded_date database:database];
	tmp_report.itts = self;
	primaryKey = tmp_report.primaryKey;
	
	// add to primary reports table
	[reports setObject:tmp_report forKey:[NSNumber numberWithInt:primaryKey]];
	
	// also add to the indexes
	switch (tmp_report.reportType) 
	{
		case ReportTypeDay:
			[reportsDaily addObject:tmp_report];
			break;
		case ReportTypeWeek:
			[reportsWeekly addObject:tmp_report];
			break;
		default:
			break;
	}
	id:	
	tmp_report.isNew = YES;
	
	newReports ++;
	[self insertReportNotification:tmp_report];
	
	[tmp_report release];
	
	
	return primaryKey;
}

- (void) insertReportLineForAppID:(NSUInteger)app_id type_id:(NSUInteger)type_id units:(NSUInteger)units
					royalty_price:(double)royalty_price royalty_currency:(NSString *)royalty_currency customer_price:(double)customer_price customer_currency:(NSString *)customer_currency country_code:(NSString *)country_code report_id:(NSUInteger)report_id
{
	//NSUInteger primaryKey = 0;
	// This query may be performed many times during the run of the application. As an optimization, a static
    // variable is used to store the SQLite compiled byte-code for the query, which is generated one time - the first
    // time the method is executed by any Book object.
    if (insert_statement_sale == nil) {
        static char *sql = "REPLACE INTO sale(app_id, type_id, units, royalty_price, royalty_currency, customer_price , customer_currency , country_code, report_id) VALUES(?, ?, ?, ?, ?, ?, ?,?,?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement_sale, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_int(insert_statement_sale, 1, app_id);
	sqlite3_bind_int(insert_statement_sale, 2, type_id);
	sqlite3_bind_int(insert_statement_sale, 3, units);
	sqlite3_bind_double(insert_statement_sale, 4, royalty_price);
	sqlite3_bind_text(insert_statement_sale, 5, [royalty_currency UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_double(insert_statement_sale, 6, customer_price);
	sqlite3_bind_text(insert_statement_sale, 7, [customer_currency UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_statement_sale, 8, [country_code UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(insert_statement_sale, 9, report_id);
	
    int success = sqlite3_step(insert_statement_sale);
	
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insert_statement_sale);
    if (success == SQLITE_ERROR) {
        NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
    } else {
        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
        // in the database. To access this functionality, the table should have a column declared of type 
        // "INTEGER PRIMARY KEY"
        //primaryKey = sqlite3_last_insert_rowid(database);
    }
    // All data for the book is already in memory, but has not be written to the database
    // Mark as hydrated to prevent empty/default values from overwriting what is in memory
    //hydrated = YES;
	
	//return primaryKey;
	
} 





- (NSUInteger) reportIDForDate:(NSString *)dayString type:(ReportType)report_type
{
	NSUInteger retID = 0;
	NSDate *tmpDate = [dayString dateFromString];
	// Compile the query for retrieving book data. See insertNewBookIntoDatabase: for more detail.
	if (reportid_statement == nil) {
		// Note the '?' at the end of the query. This is a parameter which can be replaced by a bound variable.
		// This is a great way to optimize because frequently used queries can be compiled once, then with each
		// use new variable values can be bound to placeholders.
		const char *sql = "SELECT [id] from report WHERE until_date like ? AND report_type_id = ?";
		if (sqlite3_prepare_v2(database, sql, -1, &reportid_statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
	}
	// For this query, we bind the primary key to the first (and only) placeholder in the statement.
	// Note that the parameters are numbered from 1, not from 0.
	
	sqlite3_bind_text(reportid_statement, 1, [[NSString stringWithFormat:@"%@%%", [[tmpDate description] substringToIndex:10]] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(reportid_statement, 2, (int)report_type);
	if (sqlite3_step(reportid_statement) == SQLITE_ROW) 
	{
		retID = sqlite3_column_int(reportid_statement, 0);
	} else {
	}
	// Reset the statement for future reuse.
	sqlite3_reset(reportid_statement);
	return retID;
}




- (NSIndexPath *) indexforApp:(App *)app
{
	// now get the position in the table to animate insertion for
	NSArray *sortedKeys = [self appKeysSortedBySales];
	
	NSUInteger row, section;
	
	section = 0;
	row = [sortedKeys indexOfObject:[NSNumber numberWithInt:app.apple_identifier]];
	
	return [NSIndexPath indexPathForRow:row inSection:section];
}


- (NSIndexPath *) indexforReport:(Report *)report
{
	// now get the position in the table to animate insertion for
	NSUInteger row, section;
	
	section = report.reportType;  // 0 for days, 1 for weeks
	
	NSMutableArray *tmpArray = [reportsByType objectAtIndex:section];
	
	NSSortDescriptor *dateDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"fromDate" ascending:NO] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
	NSArray *sortedArray = [tmpArray sortedArrayUsingDescriptors:sortDescriptors];
	
	row = [sortedArray indexOfObject:report];
	
	return [NSIndexPath indexPathForRow:row inSection:section];
}






















- (NSArray *) appKeysSortedBySales
{
	NSArray *sortedKeys = [apps keysSortedByValueUsingSelector:@selector(compareBySales:)];
	return sortedKeys;
}

- (NSArray *) appsSortedBySales
{
	NSArray *sortedKeys = [self appKeysSortedBySales];
	NSEnumerator *enu = [sortedKeys objectEnumerator];
	NSNumber *oneKey;
	NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:[sortedKeys count]];
	
	
	while (oneKey = [enu nextObject]) {
		App *oneApp = [apps objectForKey:oneKey];
		[tmpArray addObject:oneApp];
	}
	
	NSArray *ret = [NSArray arrayWithArray:tmpArray];
	[tmpArray release];
	
	return ret;
}








# pragma mark Post Synchronization


// finds the latest daily and weekly report and saves it in lookup dictionary
- (void)refreshIndexes
{
	NSEnumerator *e = [reports objectEnumerator];
	Report *r;
	
	while (r = [e nextObject]) 
	{
		// track which is the latest report of each type
		Report *prevLatestReport = [latestReportsByType objectForKey:[NSNumber numberWithInt:r.reportType]];
		if (!prevLatestReport || [prevLatestReport.fromDate timeIntervalSinceDate:r.fromDate]<0)
		{
			[latestReportsByType setObject:r forKey:[NSNumber numberWithInt:r.reportType]];
			
		}
		
	}
	
	[self calcAvgRoyaltiesForApps];
	
	// this gets called after EACH report, so not a good place to do totals
}

- (void)calcAvgRoyaltiesForApps
{
	// for calculations wee need the latest reports hydrated
	[[latestReportsByType objectForKey:[NSNumber numberWithInt:ReportTypeDay]] hydrate];
	[[latestReportsByType objectForKey:[NSNumber numberWithInt:ReportTypeWeek]] hydrate];
	
	
	
	// day reports, they are sorted newest first
	NSArray *dayReports = [reportsByType objectAtIndex:ReportTypeDay];
	
	NSSortDescriptor *dateDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"fromDate" ascending:NO] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
	NSArray *sortedArray = [dayReports sortedArrayUsingDescriptors:sortDescriptors];
	
	NSArray *appIDs = [apps allKeys];
	App *tmpApp;
	NSNumber *app_id;
	
	int i;
	
	int num_reports = [sortedArray count];
	if (num_reports>7)
	{
		num_reports = 7;
	}
	
	for (i=0;i<num_reports;i++)
	{
		Report *tmpReport = [sortedArray objectAtIndex:i];
		[tmpReport hydrate];
		
		
		// for each app add the royalties into the apps's average field, we'll divide it in the end
		NSEnumerator *keyEnum = [appIDs objectEnumerator];
		
		while (app_id = [keyEnum nextObject])
		{
			tmpApp = [apps objectForKey:app_id];
			
			if (!i) tmpApp.averageRoyaltiesPerDay = 0;
			
			double dayRoyalties = [tmpReport sumRoyaltiesForAppId:app_id transactionType:TransactionTypeSale];
			tmpApp.averageRoyaltiesPerDay += dayRoyalties;
			
			if (i==(num_reports-1)) tmpApp.averageRoyaltiesPerDay = tmpApp.averageRoyaltiesPerDay/(double)num_reports;
		}
	}
	
	// we could refresh the app table
}



#pragma mark Import / Export

- (void) importReportsFromDocumentsFolder
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
	// NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	
	// get list of all files in document directory
	NSArray *docs = [fileManager directoryContentsAtPath:documentsDirectory];
	NSEnumerator *enu = [docs objectEnumerator];
	NSString *aString;
	
	while (aString = [enu nextObject])
	{
		if ([[aString lowercaseString] hasSuffix:@".txt"])
		{
			//NSLog(@"Found report %@", aString);
			NSString *pathOfFile = [documentsDirectory stringByAppendingPathComponent:aString];
			
			NSString *string = [NSString stringWithContentsOfFile:pathOfFile];
			[self addReportToDBfromString:string];
			[self refreshIndexes];  // this causes avgRoyalties calc

			[fileManager removeItemAtPath:pathOfFile error:NULL];
		}
		else if ([[aString lowercaseString] hasSuffix:@".zip"])
		{
			//NSLog(@"Found report archive %@", aString);
			NSString *pathOfFile = [documentsDirectory stringByAppendingPathComponent:aString];
			//NSString *unzipDir = [documentsDirectory stringByAppendingPathComponent:@"unzipped"];
			
			
			ZipArchive *zip = [[ZipArchive alloc] init];
			
			[zip UnzipOpenFile:pathOfFile];
			NSArray *datas = [zip UnzipFileToDataArray];
			
			if (!self.dataToImport)
			{
				self.dataToImport = [NSMutableArray arrayWithArray:datas];
			}
			else
			{
				[self.dataToImport addObjectsFromArray:datas];
			}
			
			/*
			 NSEnumerator *enu = [datas objectEnumerator];
			 NSData *oneData;
			 
			 while (oneData = [enu nextObject]) 
			 {
			 NSString *string = [[NSString alloc] initWithBytes:[oneData bytes] length:[oneData length] encoding:NSUTF8StringEncoding];
			 [self addReportToDBfromString:string];
			 [string release];
			 }
			 */
			
			[zip CloseZipFile2];
			[zip release];
			[fileManager removeItemAtPath:pathOfFile error:NULL];
			
			[NSTimer scheduledTimerWithTimeInterval: 0.5
											 target: self
										   selector: @selector(workImportQueue:)
										   userInfo: nil
											repeats: NO];
			
			
			//NSString *string = [NSString stringWithContentsOfFile:pathOfFile];
			//[self addReportToDBfromString:string];
			//[fileManager removeItemAtPath:pathOfFile error:NULL];
		}
		
		
	}
}


- (void)workImportQueue:(id)sender
{
	if (!dataToImport) return;
	
	NSData *oneData = [dataToImport objectAtIndex:0];
	NSString *string = [[NSString alloc] initWithBytes:[oneData bytes] length:[oneData length] encoding:NSUTF8StringEncoding];
	[self addReportToDBfromString:string];
	[string release];

	[dataToImport removeObject:oneData];
	
	if ([dataToImport count]>0)
	{
		[self setStatus:[NSString stringWithFormat:@"Importing Reports (%d left)", [dataToImport count]]];
		
		[NSTimer scheduledTimerWithTimeInterval: 1.5
										 target: self
									   selector: @selector(workImportQueue:)
									   userInfo: nil
										repeats: NO];
		
	}
	else
	{
		[self setStatus:@"Importing Reports Done"];
		[self setStatus:nil];
		
		[dataToImport release];
		dataToImport = nil;
		
		[self refreshIndexes];  // this causes avgRoyalties calc

	}
}

- (NSString *) reportTextForID:(NSInteger)report_id
{
	Report *theReport = [reports objectForKey:[NSNumber numberWithInt:report_id]];
	
	if (!theReport)
	{
		return @"";
	}
	
	return [theReport reconstructText];
}

- (NSString *) createZipFromReportsOfType:(ReportType)type
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *type_string;
	NSString *file_prefix;
	
	switch (type) {
		case ReportTypeDay:
			type_string = @"daily";
			file_prefix = @"S_D_";
			break;
		case ReportTypeWeek:
			type_string = @"weekly";
			file_prefix = @"S_W_";
			break;
		default:
			break;
	}
	NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"reports_%@.zip", type_string]];
	
	ZipArchive *zip = [[ZipArchive alloc] init];
	
	[zip CreateZipFile2:path]; 
	
	NSEnumerator *enu = [[self.reportsByType objectAtIndex:type] objectEnumerator];
	Report *oneReport;
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"yyyyMMdd"];
	
	
	while (oneReport = [enu nextObject]) 
	{
		NSString *s = [oneReport reconstructText];
		NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
		NSString *nameInZip = [NSString stringWithFormat:@"reports/%@%@.txt", file_prefix, [df stringFromDate:oneReport.fromDate]];
		[zip addDataAsFileToZip:d newname:nameInZip fileDate:oneReport.downloadedDate];
	}
	
	[df release];
	[zip CloseZipFile2];
	[zip release];
	
	return path;
}

#pragma mark Notifications and Counters
- (void) newReportRead:(Report *)report;
{
	if (!report.isNew)
	{
		return;
	}
	
	// new code for local tracking of number of daily/weekly
	NSNumber *typeKey = [NSNumber numberWithInt:report.reportType];
	NSNumber *theNum = [newReportsByType objectForKey:typeKey];
	if (theNum)
	{
		NSNumber *newNum = [NSNumber numberWithInt:[theNum intValue]-1];
		[newReportsByType setObject:newNum forKey:typeKey];
	}
	
	// old code for notification
	report.isNew = NO;
	newReports--;
	
	NSArray *values = [NSArray arrayWithObjects:report, [NSNumber numberWithInt:newReports], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"Report", @"NewReports", nil];
	
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
	
	
	// refresh Badges
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewReportRead" object:nil userInfo:tmpDict];

}

- (NSUInteger) numberOfNewReportsOfType:(NSUInteger)reportType
{
	NSNumber *typeKey = [NSNumber numberWithInt:reportType];
	return [[newReportsByType objectForKey:typeKey] intValue];
}

- (void)exchangeRatesChanged:(NSNotification *) notification
{
	// different exchange rates require that we redo the totals
	[self getTotals]; 
}



#pragma mark Database
// Creates a writable copy of the bundled default database in the application Documents directory.
- (void)createEditableCopyOfDatabaseIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"apps.db"];
	//NSLog(@"DB: %@", writableDBPath);
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"apps.db"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}


// Open the database connection and retrieve minimal information for all objects.
- (void)initializeDatabase {
    self.apps = [[NSMutableDictionary alloc] init];
    self.reports = [[NSMutableDictionary alloc] init];
	
	
    // The database is stored in the application bundle. 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"apps.db"];
    // Open the database. The database was prepared outside the application.
    if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) 
	{
        // Get the primary key for all books.
		char *sql = "SELECT id FROM app";
		sqlite3_stmt *statement;
		// Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
		// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.        
		if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
		{
			// We "step" through the results - once for each row.
			while (sqlite3_step(statement) == SQLITE_ROW) 
			{
				// The second parameter indicates the column index into the result set.
				int primaryKey = sqlite3_column_int(statement, 0);
				
				// We avoid the alloc-init-autorelease pattern here because we are in a tight loop and
				// autorelease is slightly more expensive than release. This design choice has nothing to do with
				// actual memory management - at the end of this block of code, all the book objects allocated
				// here will be in memory regardless of whether we use autorelease or release, because they are
				// retained by the books array.
				App *app = [[App alloc] initWithPrimaryKey:primaryKey database:database];
				
				[apps setObject:app forKey:[NSNumber numberWithInt:primaryKey]];
				[app release];
			}
		}
		// "Finalize" the statement - releases the resources associated with the statement.
		sqlite3_finalize(statement); 
		
		// Get the primary key for all reports.
		sql = "SELECT id FROM report order by from_date";
		
		if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
		{
			// We "step" through the results - once for each row.
			while (sqlite3_step(statement) == SQLITE_ROW) 
			{
				// The second parameter indicates the column index into the result set.
				int primaryKey = sqlite3_column_int(statement, 0);
				
				// We avoid the alloc-init-autorelease pattern here because we are in a tight loop and
				// autorelease is slightly more expensive than release. This design choice has nothing to do with
				// actual memory management - at the end of this block of code, all the book objects allocated
				// here will be in memory regardless of whether we use autorelease or release, because they are
				// retained by the books array.
				Report *report = [[Report alloc] initWithPrimaryKey:primaryKey database:database];
				report.itts = self;
				
				[reports setObject:report forKey:[NSNumber numberWithInt:primaryKey]];
				
				// also add to the indexes
				switch (report.reportType) 
				{
					case ReportTypeDay:
						[reportsDaily addObject:report];
						break;
					case ReportTypeWeek:
						[reportsWeekly addObject:report];
						break;
					default:
						break;
				}
				[report release];
			}
		}
		// "Finalize" the statement - releases the resources associated with the statement.
		sqlite3_finalize(statement);
		
		
    } 
	else 
	{
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(database);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
        // Additional error handling, as appropriate...
    }
}


@end
