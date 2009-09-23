//
//  ItunesConnectDownloaderOperation.m
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "ItunesConnectDownloaderOperation.h"
#import "NSString+Helpers.h"
#import "Account.h"
#import "DDData.h"
#import "Database.h"

#import "NSArray+Reports.h"


@implementation ItunesConnectDownloaderOperation

@synthesize reportsToIgnore, delegate;

- (id) initForAccount:(Account *)itcAccount
{
	if (self = [super init])
	{
		account = [itcAccount retain];
		workInProgress = YES;
	}
	
	return self;
}

- (void) dealloc
{
	[account release];
	
	[super dealloc];
}


- (void) failWithMessage:(NSString *)message
{
	[self setStatusError:message];
	workInProgress = NO;
	[self performSelectorOnMainThread:@selector(sendFinishToDelegate) withObject:nil waitUntilDone:YES];
}



- (BOOL) needToDownloadFinancialReportWithFilename:(NSString *)fileName
{
	NSLog(@"%@", fileName);
	NSArray *split = [[fileName stringByReplacingOccurrencesOfString:@".txt" withString:@""] componentsSeparatedByString:@"_"];
	
	NSString *reportMonth = [split objectAtIndex:1];
	NSString *regionCode = [split objectAtIndex:2];
	
	if ([split count]>3)
	{
		return NO;
	}
	
	ReportRegion region;
	
	if ([regionCode isEqualToString:@"US"]) region = ReportRegionUSA;
	else if ([regionCode isEqualToString:@"GB"]) region = ReportRegionUK;
	else if ([regionCode isEqualToString:@"JP"]) region = ReportRegionJapan;
	else if ([regionCode isEqualToString:@"AU"]) region = ReportRegionAustralia;
	else if ([regionCode isEqualToString:@"CA"]) region = ReportRegionCanada;
	else if ([regionCode isEqualToString:@"EU"]) region = ReportRegionEurope;
	else if ([regionCode isEqualToString:@"WW"]) region = ReportRegionRestOfWorld;
	else region = ReportRegionUnknown;

	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateFormat:@"MMYY"];
	
	for (Report *oneReport in reportsToIgnore)
	{
		if (oneReport.reportType == ReportTypeFinancial)
		{
			NSDate *middleDate = [oneReport dateInMiddleOfReport];
			NSString *oneReportMonth = [df stringFromDate:middleDate];
		
			if ([oneReportMonth isEqualToString:reportMonth]&&(oneReport.region == region))
			{
				return NO;
			}
		}
	}
	
	return YES;
}




- (void) main
{
	if (!(account.account&&account.password&&![account.account isEqualToString:@""]&&![account.password isEqualToString:@""]))
	{
		return;
	}
	
	// main thread
	if (delegate && [delegate respondsToSelector:@selector(downloadStartedForOperation:)])
	{
		[delegate performSelectorOnMainThread:@selector(downloadStartedForOperation:) withObject:self waitUntilDone:NO];
	}
	
	// remove all previous cookies
	NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	for (NSHTTPCookie *oneCookie in [cookies cookies])
	{
		[cookies deleteCookie:oneCookie];
	}
	
	// open login page
	NSString *URL=[NSString stringWithFormat:@"https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa"];
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
														 cachePolicy:NSURLRequestReloadIgnoringCacheData
													 timeoutInterval:30.0];	
	NSURLResponse* response; 
	NSError* error;
	
	[self setStatus:@"Opening HTTPS Connection"];

	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from login screen request"];
		return;
	}
	
	NSString *sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	// search for outer post url
	NSString *post_url = [sourceSt stringByFindingFormPostURLwithName:nil];
	
	if (!post_url)
	{
		[self setStatusError:@"No form post URL found! (Login Screen)"];
		return;
	}
	
	URL = [@"https://itunesconnect.apple.com" stringByAppendingString:post_url];
	
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
								timeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"theAccountName=%@&theAccountPW=%@&1.Continue.x=20&1.Continue.y=6&theAuxValue=", 
						   [account.account stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
						   [account.password stringByUrlEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	
	[self setStatus:@"Sending Login Information"];
	
	data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	/*if ([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
		NSLog(@"%@", [http allHeaderFields]);
	}*/
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from login"];
		return;
	}
	
	
	sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	// check if we received a login session cookies
	NSArray *sessionCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://www.apple.com"]];
	
	if (![sessionCookies count])
	{
		[self setStatusError:@"Login Failed"];
		return;
	}
	
	
	NSString *financialUrl = [sourceSt hrefForLinkContainingText:@"Financial"];

	[NSThread sleepForTimeInterval:1]; // experiment: slow down to prevent timeout changing to itts
	
	// open "Piano" reporting page
	URL = @"http://itts.apple.com/cgi-bin/WebObjects/Piano.woa";
	
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:60.0];  // might take long
	
	[request setHTTPMethod:@"GET"];
	
	[self setStatus:@"Accessing Sales Reports"];
	
	data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from Piano"];
		return;
	}
	
	sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	// search for outer post url
	post_url = [sourceSt stringByFindingFormPostURLwithName:@"frmVendorPage"];
	
	if (!post_url)
	{
		[self setStatusError:@"No form post URL found! (Piano Screen)"];
		//NSLog(@"%@", sourceSt);
		return;
	}
	
	// DAY OPTIONS
	
	URL = [@"https://itts.apple.com" stringByAppendingString:post_url];
	
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	postBody = [NSMutableData data];
	[postBody appendData:[@"11.7=Summary&11.9=Daily&hiddenDayOrWeekSelection=Daily&hiddenSubmitTypeName=ShowDropDown" dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	
	[self setStatus:@"Retrieving Day Options"];
	
	data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from day options"];
		return;
	}
	sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	// search for frmVendorPage URL
	post_url = [sourceSt stringByFindingFormPostURLwithName:@"frmVendorPage"];
	
	if (!post_url)
	{
		[self setStatusError:@"Unrecognized response from day options"];
		
		NSLog(@"%@", sourceSt);
		return;
	}
	
	//URL = [@"https://itts.apple.com" stringByAppendingString:post_url];
	
	
	// get list of available day reports
	
	NSRange selectRange = [sourceSt rangeOfString:@"<select Id=\"dayorweekdropdown\""];
	if (selectRange.location==NSNotFound)
	{
		[self setStatusError:@"No day options found"];
		return;
	}
	
	NSRange endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:NSMakeRange(selectRange.location, 1000)];
	NSArray *dayOptions = [[sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)] optionsFromSelect];
	
	for (NSString *oneDayOption in dayOptions)
	{
		NSString *formDate = [oneDayOption stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
		
		NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
		[df setDateFormat:@"MM/dd/yyyy"];
		NSDate *reportDate = [df dateFromString:oneDayOption];
		
		if (![reportsToIgnore reportBySearchingForDate:reportDate type:ReportTypeDay region:ReportRegionUnknown])
		{
			[self setStatus:@"Retrieving Day Options"];
			
			URL = [@"https://itts.apple.com" stringByAppendingString:post_url];
			
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestUseProtocolCachePolicy
										timeoutInterval:30.0];
			
			[request setHTTPMethod:@"POST"];
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
			
			//create the body
			postBody = [NSMutableData data];
			NSString *body = [NSString stringWithFormat:@"11.7=Summary&11.9=Daily&11.11.1=%@&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=Download", formDate, formDate];
			[postBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
			
			//add the body to the post
			[request setHTTPBody:postBody];
		
			[self setStatus:[NSString stringWithFormat:@"Loading Day Report for %@", oneDayOption]];

			
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			if (error)
			{
				[self setStatusError:[error localizedDescription]];
				return;
			}
			
			if (!data) 
			{
				[self setStatusError:@"No data received from request day report"];

				return;
			}
			
			NSData *decompressed = [data gzipInflate];
			NSString *decompStr = [[[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSASCIIStringEncoding] autorelease];
			
			[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromText:) withObject:decompStr waitUntilDone:YES];
		}
	}
	
	
	// select week options
	
	URL = [@"https://itts.apple.com" stringByAppendingString:post_url];		  
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	postBody = [NSMutableData data];
	[postBody appendData:[@"11.7=Summary&11.9=Weekly&hiddenDayOrWeekSelection=Weekly&hiddenSubmitTypeName=ShowDropDown" dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	
	[self setStatus:@"Retrieving Week Options"];
	
	data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from week options"];
		return;
	}
	sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	selectRange = [sourceSt rangeOfString:@"<select Id=\"dayorweekdropdown\""];
	
	if (selectRange.location==NSNotFound)
	{
		[self setStatusError:@"No day options found"];
		return;
	}
	
	endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:NSMakeRange(selectRange.location, 1000)];
	NSArray *weekOptions = [[[sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)] optionsFromSelect] retain];
	
	
	for (NSString *oneWeekOption in weekOptions)
	{
		NSString *formDate = [oneWeekOption stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
		
		NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
		[df setDateFormat:@"MM/dd/yyyy"];
		NSDate *reportDate = [df dateFromString:oneWeekOption];
		
		if (![reportsToIgnore reportBySearchingForDate:reportDate type:ReportTypeWeek region:ReportRegionUnknown])
		{
			[self setStatus:[NSString stringWithFormat:@"Loading Week Report for %@", oneWeekOption]];

			URL = [@"https://itts.apple.com" stringByAppendingString:post_url];
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestUseProtocolCachePolicy
										timeoutInterval:30.0];
			
			[request setHTTPMethod:@"POST"];
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
			
			//create the body
			postBody = [NSMutableData data];
			NSString *body = [NSString stringWithFormat:@"11.7=Summary&11.9=Weekly&11.13.1=%@&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=Download", formDate, formDate];
			[postBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
			
			//add the body to the post
			[request setHTTPBody:postBody];
			
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			if (error)
			{
				[self setStatusError:[error localizedDescription]];
				return;
			}
			
			if (!data) 
			{
				[self setStatusError:@"No data received from request day report"];
				return;
			}
			
			NSData *decompressed = [data gzipInflate];
			NSString *decompStr = [[[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSASCIIStringEncoding] autorelease];
			
			[DB performSelectorOnMainThread:@selector(insertReportFromText:) withObject:decompStr waitUntilDone:YES];
		}
		
	}	
	
	// select week options
	
	URL = [@"https://itts.apple.com" stringByAppendingString:post_url];		  
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	postBody = [NSMutableData data];
	[postBody appendData:[@"11.7=Summary&11.9=Monthly%20Free&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=ShowDropDown" dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	
	[self setStatus:@"Retrieving Free Options"];
	
	data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from free options"];
		return;
	}
	sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	selectRange = [sourceSt rangeOfString:@"<select Id=\"dayorweekdropdown\""];
	
	if (selectRange.location==NSNotFound)
	{
		[self setStatusError:@"No monthly free options found"];
		return;
	}
	
	endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:NSMakeRange(selectRange.location, 1000)];
	NSArray *monthlyFreeOptions = [[sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)] optionsFromSelect];
	
	
	for (NSString *oneMonthlyFreeOption in monthlyFreeOptions)
	{
		NSString *formDate = [oneMonthlyFreeOption stringByUrlEncoding];
				
		NSArray *tmpArray = [oneMonthlyFreeOption componentsSeparatedByString:@"#"];

		NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
		[df setDateFormat:@"yyyyMMdd"];
		NSDate *fromDate = [df dateFromString:[tmpArray objectAtIndex:0]];
		NSDate *untilDate = [df dateFromString:[tmpArray objectAtIndex:1]];
		
		[df setDateStyle:NSDateFormatterShortStyle];
		
		
		
		if (![reportsToIgnore reportBySearchingForDate:untilDate type:ReportTypeFree region:ReportRegionUnknown])
		{
			[self setStatus:[NSString stringWithFormat:@"Loading Free Report for %@", [df stringFromDate:fromDate]]];
			
			URL = [@"https://itts.apple.com" stringByAppendingString:post_url];
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestUseProtocolCachePolicy
										timeoutInterval:30.0];
			
			[request setHTTPMethod:@"POST"];
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
			
			//create the body
			postBody = [NSMutableData data];
			NSString *body = [NSString stringWithFormat:@"11.7=Summary&11.9=Monthly%%20Free&11.14.1=%@&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=Download", formDate, formDate];
			[postBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
			
			//add the body to the post
			[request setHTTPBody:postBody];
			
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			if (error)
			{
				[self setStatusError:[error localizedDescription]];
				return;
			}
			
			if (!data) 
			{
				[self setStatusError:@"No data received from request free report"];
				return;
			}
			
			NSData *decompressed = [data gzipInflate];
			NSString *decompStr = [[[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSASCIIStringEncoding] autorelease];
			
			NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:decompStr, @"Text", untilDate, @"UntilDate", fromDate, @"FromDate", nil];
			
			[DB performSelectorOnMainThread:@selector(insertMonthlyFreeReportFromFromDict:) withObject:tmpDict waitUntilDone:YES];
		}
		
	}	
	
	
	URL = [@"https://itunesconnect.apple.com" stringByAppendingString:financialUrl];
	
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:60.0];  // might take long
	
	[request setHTTPMethod:@"GET"];
	
	[self setStatus:@"Accessing Financial Reports"];
	
	NSUInteger financialsDownloaded = 0;
	
	data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from FR"];
		return;
	}
	
	sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	NSString *nextUrl = [sourceSt hrefForLinkContainingText:@"rt-OSarw.gif"];
	
	NSArray *reportURLs = [sourceSt arrayWithHrefDicts];
	
	for (NSDictionary *oneDict in reportURLs)
	{
		NSString *url = [oneDict objectForKey:@"url"];
		NSString *text = [oneDict objectForKey:@"contents"];
		
		if ([text hasSuffix:@".txt"]&&[self needToDownloadFinancialReportWithFilename:text])
		{
			URL = [@"https://itunesconnect.apple.com" stringByAppendingString:url];
			
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestUseProtocolCachePolicy
										timeoutInterval:60.0];  // might take long
			
			[request setHTTPMethod:@"GET"];
			
			
			[self setStatus:[@"Loading " stringByAppendingString:text]];
			
			financialsDownloaded++;
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			/*if ([response isKindOfClass:[NSHTTPURLResponse class]])
			 {
			 NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
			 NSLog(@"%@", [http allHeaderFields]);
			 }*/
			
			
			if (error)
			{
				[self setStatusError:[error localizedDescription]];
				return;
			}
			
			if (!data) 
			{
				[self setStatusError:@"No data received from FR"];
				return;
			}
			
			sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
			
			[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromText:) withObject:sourceSt waitUntilDone:YES];
			
		}
	}
	
	// to to next page if possible and if we at least downloaded one report on first page
	while (financialsDownloaded&&nextUrl)
	{
		financialsDownloaded = 0;  // only go to next page if there was something new on this one
		
		URL = [@"https://itunesconnect.apple.com" stringByAppendingString:nextUrl];
		
		request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
										cachePolicy:NSURLRequestUseProtocolCachePolicy
									timeoutInterval:60.0];  // might take long
		
		[request setHTTPMethod:@"GET"];
		
		data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		
		
		if (error)
		{
			[self setStatusError:[error localizedDescription]];
			return;
		}
		
		if (!data) 
		{
			[self setStatusError:@"No data received from FR"];
			return;
		}
		
		sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
		
		nextUrl = [sourceSt hrefForLinkContainingText:@"rt-OSarw.gif"];
		
		NSArray *reportURLs = [sourceSt arrayWithHrefDicts];
		
		for (NSDictionary *oneDict in reportURLs)
		{
			NSString *url = [oneDict objectForKey:@"url"];
			NSString *text = [oneDict objectForKey:@"contents"];
			
			if ([text hasSuffix:@".txt"]&&[self needToDownloadFinancialReportWithFilename:text])
			{
				URL = [@"https://itunesconnect.apple.com" stringByAppendingString:url];
				
				request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
												cachePolicy:NSURLRequestUseProtocolCachePolicy
											timeoutInterval:60.0];  // might take long
				
				[request setHTTPMethod:@"GET"];
				
				
				[self setStatus:[@"Loading " stringByAppendingString:text]];
				
				data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
				financialsDownloaded++;
				
				/*if ([response isKindOfClass:[NSHTTPURLResponse class]])
				 {
				 NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
				 NSLog(@"%@", [http allHeaderFields]);
				 }*/
				
				
				if (error)
				{
					[self setStatusError:[error localizedDescription]];
					return;
				}
				
				if (!data) 
				{
					[self setStatusError:@"No data received from FR"];
					return;
				}
				
				sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
				
				[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromText:) withObject:sourceSt waitUntilDone:YES];
				
			}
		}
	}
	
	
	
	
	[self setStatusSuccess:@"Synchronization Done"];
	//[self setStatus:nil];
}


- (BOOL) isConcurrent
{
	return NO;
}

- (BOOL) isFinished
{
	return !workInProgress;
}

#pragma mark Status

- (void) sendFinishToDelegate
{
	// main thread
	if (delegate && [delegate respondsToSelector:@selector(downloadFinishedForOperation:)])
	{
		[delegate performSelectorOnMainThread:@selector(downloadFinishedForOperation:) withObject:self waitUntilDone:NO];
	}
}

- (void) sendStatusNotification:(id)message
{
	// need to send notifications on main thread
	[[NSNotificationCenter defaultCenter] postNotificationName:@"StatusMessage" object:nil userInfo:(id)message];
}

- (void) setStatus:(NSString *)message
{
	[self performSelectorOnMainThread:@selector(sendStatusNotification:) withObject:(id)message waitUntilDone:NO];
}

- (void) setStatusError:(NSString *)message
{
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", @"Error", @"type", nil];
	[self performSelectorOnMainThread:@selector(sendStatusNotification:) withObject:(id)tmpDict waitUntilDone:NO];
	workInProgress = NO;
	[self sendFinishToDelegate];
}

- (void) setStatusSuccess:(NSString *)message
{
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", @"Success", @"type", nil];
	[self performSelectorOnMainThread:@selector(sendStatusNotification:) withObject:(id)tmpDict waitUntilDone:NO];
	workInProgress = NO;
	[self sendFinishToDelegate];
}

@end
