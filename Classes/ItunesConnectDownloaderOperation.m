//
//  ItunesConnectDownloaderOperation.m
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "ItunesConnectDownloaderOperation.h"
#import "NSString+Helpers.h"
#import "NSString+scraping.h"
#import "GenericAccount.h"
#import "DDData.h"
#import "Database.h"

#import "NSArray+Reports.h"
#import "NSDate+Helpers.h"


@implementation ItunesConnectDownloaderOperation

@synthesize reportsToIgnore, delegate;

- (id) initForAccount:(GenericAccount *)itcAccount
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


- (ReportRegion)regionFromCode:(NSString *)regionCode
{
	ReportRegion region;
	if ([regionCode isEqualToString:@"US"]) region = ReportRegionUSA;
	else if ([regionCode isEqualToString:@"GB"]) region = ReportRegionUK;
	else if ([regionCode isEqualToString:@"JP"]) region = ReportRegionJapan;
	else if ([regionCode isEqualToString:@"AU"]) region = ReportRegionAustralia;
	else if ([regionCode isEqualToString:@"CA"]) region = ReportRegionCanada;
	else if ([regionCode isEqualToString:@"EU"]) region = ReportRegionEurope;
	else if ([regionCode isEqualToString:@"WW"]) region = ReportRegionRestOfWorld;
	else region = ReportRegionUnknown;
	
	return region;
}

- (ReportRegion)regionFromString:(NSString *)string
{
	if ([string isEqualToString:@"Americas"])
	{
		return ReportRegionUSA;
	}
	
	if ([string isEqualToString:@"Australia"])
	{
		return ReportRegionAustralia;
	}
	
	if ([string isEqualToString:@"Canada"])
	{
		return ReportRegionCanada;
	}
	
	if ([string isEqualToString:@"Euro-Zone"])
	{
		return ReportRegionEurope;
	}
	
	if ([string isEqualToString:@"Japan"])
	{
		return ReportRegionJapan;
	}
	
	if ([string isEqualToString:@"Rest of World"])
	{
		return ReportRegionRestOfWorld;
	}
	
	if ([string isEqualToString:@"United Kingdom"])
	{
		return ReportRegionUK;
	}
	
	return ReportRegionUnknown;
}

- (NSDate *)reportDateFromString:(NSString *)string
{
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"MMM y"];
	
	return [formatter dateFromString:string];
}

- (BOOL) needToDownloadFinancialReportWithFilename:(NSString *)fileName region:(ReportRegion *)foundRegion month:(int *)foundMonth year:(int *)foundYear
{
	NSArray *split = [[fileName stringByReplacingOccurrencesOfString:@".txt" withString:@""] componentsSeparatedByString:@"_"];
	
	NSString *reportMonth = [split objectAtIndex:1];
	NSString *regionCode = [split objectAtIndex:2];
	
	if ([split count]>3) // causes Payment Reports to be ignored.
	{
		return NO;
	}
	
	ReportRegion region = [self regionFromCode:regionCode];
	
	if (foundRegion)
	{
		*foundRegion = region;
	}
	
	if (foundMonth)
	{
		*foundMonth = [[reportMonth substringToIndex:2] intValue];
	}
	
	if (foundYear)
	{
		*foundYear = [[reportMonth substringFromIndex:2] intValue];
	}
	
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateFormat:@"MMYY"];
	
	for (Report_v1 *oneReport in reportsToIgnore)
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

- (BOOL)needToDownloadFinancialReportWithDate:(NSDate *)date region:(ReportRegion)region
{
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateFormat:@"MMYY"];

	NSString *checkMonth = [df stringFromDate:date];
	
	for (Report_v1 *oneReport in reportsToIgnore)
	{
		if (oneReport.reportType == ReportTypeFinancial)
		{
			NSDate *middleDate = [oneReport dateInMiddleOfReport];
			NSString *oneReportMonth = [df stringFromDate:middleDate];
			
			if ([oneReportMonth isEqualToString:checkMonth]&&(oneReport.region == region))
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
	
	NSString *financialUrl = nil;
	
	// open login page
	NSString *URL=[NSString stringWithFormat:@"https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa"];
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
														 cachePolicy:NSURLRequestReloadIgnoringCacheData
													 timeoutInterval:60.0];	
	NSURLResponse* response; 
	NSError* error = nil;
	
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
	
	if (post_url)
	{
		// login form on ITC 
		
		URL = [@"https://itunesconnect.apple.com" stringByAppendingString:post_url];
		
		request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
										cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
									timeoutInterval:60.0];
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
		
		financialUrl = [sourceSt hrefForLinkContainingText:@"Financial"];
		
		[NSThread sleepForTimeInterval:1]; // experiment: slow down to prevent timeout changing to itts
		
	}
	else
	{
		// try login via ITTS
		
		// login form on ITC 
		
		URL = @"https://itts.apple.com/cgi-bin/WebObjects/Piano.woa";
		
		NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
															 cachePolicy:NSURLRequestReloadIgnoringCacheData
														 timeoutInterval:60.0];	
		NSURLResponse* response = nil; 
		NSError* error = nil;
		
		[self setStatus:@"ITC offline, trying ITTS"];
		
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

		if (post_url)
		{
			// login form on ITC 
			
			URL = [@"https://itts.apple.com" stringByAppendingString:post_url];
			
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
										timeoutInterval:60.0];
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
			
			
			//sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
			
			// check if we received a login session cookies
			NSArray *sessionCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://www.apple.com"]];
			
			if (![sessionCookies count])
			{
				[self setStatusError:@"Login Failed"];
				return;
			}
			
			alternateLogin = YES;
		}
	}

	
	
	
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
		// might be vendor selection screen
		
		NSRange vendorCheck = [sourceSt rangeOfString:@"Vendor Options"];
		
		if (vendorCheck.length>0)
		{
			post_url = [sourceSt stringByFindingFormPostURLwithName:@"superPage"];
			
			NSRange selectRange = [sourceSt rangeOfString:@"<select Id=\"selectName\""];
			if (selectRange.location==NSNotFound)
			{
				[self setStatusError:@"No vendor options found"];
				return;
			}
			
			NSRange selectSearchRange = NSMakeRange(selectRange.location, [sourceSt length] - selectRange.location);
			NSRange endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:selectSearchRange];
			
			NSArray *vendorOptions = [[sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)] optionsFromSelect];
			NSArray *sortedVendorOptions = [vendorOptions sortedArrayUsingSelector:@selector(compare:)];
			
			NSString *selectedVendor = [sortedVendorOptions lastObject];
			
			// get wosid
			
			NSString *wosid = nil;
			NSArray *inputs = [sourceSt arrayOfInputsForForm:@"superPage"];
			
			for (NSDictionary *oneDict in inputs)
			{
				NSString *attrName = [oneDict objectForKey:@"name"];
				if ([attrName isEqualToString:@"wosid"])
				{
					wosid = [oneDict objectForKey:@"value"];
				}
			}
			
			URL = [@"https://itts.apple.com" stringByAppendingString:post_url];
			
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestUseProtocolCachePolicy
										timeoutInterval:60.0];
			[request setHTTPMethod:@"POST"];
			[request addValue:@"multipart/form-data; boundary=----WebKitFormBoundaryVEGJrwgXACBaxvAp" forHTTPHeaderField: @"Content-Type"];
			[request addValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_1; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9" forHTTPHeaderField:@"User-Agent"];
			
			// build the body as string
			
			NSMutableString *bodyString = [NSMutableString string];
			
			/*
			 // original 1st post
			 [bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\r\n"];
			 [bodyString appendFormat:@"Content-Disposition: form-data; name=\"9.6.0\"\r\n\r\n%@\r\n", selectedVendor];
			 
			 [bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\r\n"];
			 [bodyString appendFormat:@"Content-Disposition: form-data; name=\"vndrid\"\r\n\r\n%@\r\n", selectedVendor];
			 
			 [bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\r\n"];
			 [bodyString appendString:@"Content-Disposition: form-data; name=\"9.18\"\r\n\r\n\r\n"];
			 
			 [bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\n"];
			 [bodyString appendFormat:@"Content-Disposition: form-data; name=\"wosid\"\r\n\r\n%@\r\n", wosid];
			 
			 [bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp--\r\n"];
			 */
			
			[bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\r\n"];
			[bodyString appendFormat:@"Content-Disposition: form-data; name=\"9.6.0\"\r\n\r\n0\r\n"];
			
			[bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\r\n"];
			[bodyString appendFormat:@"Content-Disposition: form-data; name=\"vndrid\"\r\n\r\n%@\r\n", selectedVendor];
			
			[bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\r\n"];
			[bodyString appendString:@"Content-Disposition: form-data; name=\"9.18\"\r\n\r\n\r\n"];
			
			[bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\r\n"];
			[bodyString appendString:@"Content-Disposition: form-data; name=\"SubmitBtn\"\r\n\r\nSubmit\r\n"];
			
			[bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp\r\n"];
			[bodyString appendFormat:@"Content-Disposition: form-data; name=\"wosid\"\r\n\r\n%@\r\n", wosid];
			
			[bodyString appendString:@"------WebKitFormBoundaryVEGJrwgXACBaxvAp--\r\n"];
			
			//create the body
			NSMutableData *postBody = [NSMutableData data];
			[postBody appendData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
			[request setHTTPBody:postBody];
			
			[self setStatus:@"Selecting Vendor"];
			
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			if (error)
			{
				[self setStatusError:[error localizedDescription]];
				return;
			}
			
			if (!data) 
			{
				[self setStatusError:@"No data received (vendor selection)"];
				return;
			}
			sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
			
			// search for outer post url
			post_url = [sourceSt stringByFindingFormPostURLwithName:@"frmVendorPage"];
			
			if (!post_url)
			{
				[self setStatusError:@"Reporting Site offline (Multi)"];
				return;
			}
		}
		else 
		{
			[self setStatusError:@"Reporting Site offline"];
			return;
		}
	}
	
	// DAY OPTIONS
	
	// get wosid
	
	NSString *wosid = nil;
	NSArray *inputs = [sourceSt arrayOfInputsForForm:@"superPage"];
	
	for (NSDictionary *oneDict in inputs)
	{
		NSString *attrName = [oneDict objectForKey:@"name"];
		if ([attrName isEqualToString:@"wosid"])
		{
			wosid = [oneDict objectForKey:@"value"];
		}
	}
	
	NSString *selReportType = [sourceSt nameForTag:@"select" WithID:@"selReportType"];
	NSString *selDateType = [sourceSt nameForTag:@"select" WithID:@"selDateType"];
	
	URL = [@"https://itts.apple.com" stringByAppendingString:post_url];
	
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	NSMutableData *postBody = [NSMutableData data];
	NSString *body = [NSString stringWithFormat:@"%@=Summary&%@=Daily&hiddenDayOrWeekSelection=Daily&hiddenSubmitTypeName=ShowDropDown&wosid=%@", selReportType, selDateType, wosid];
	
	[postBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
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
	
	
	NSRange selectSearchRange = NSMakeRange(selectRange.location, [sourceSt length] - selectRange.location);
	NSRange endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:selectSearchRange];
	
	NSString *selectString = [sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)];
	NSArray *dayOptions = [selectString optionsFromSelect];
	NSString *dayorweekdropdownName = [[selectString dictionaryOfAttributesFromTag] objectForKey:@"name"];	
	selReportType = [sourceSt nameForTag:@"select" WithID:@"selReportType"];
	selDateType = [sourceSt nameForTag:@"select" WithID:@"selDateType"];
	
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
										timeoutInterval:60.0];
			
			[request setHTTPMethod:@"POST"];
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
			
			//create the body
			postBody = [NSMutableData data];
			
			// 11.9=Summary&11.11=Daily&11.13.1=11%2F18%2F2009&hiddenDayOrWeekSelection=11%2F18%2F2009&hiddenSubmitTypeName=Download&wosid=Mtdy6wbxuKXHn18hhgv17M
			NSString *body = [NSString stringWithFormat:@"%@=Summary&%@=Daily&%@=%@&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=Download&wosid=%@", selReportType, selDateType, dayorweekdropdownName, formDate, formDate, wosid];
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
			
			if ([response isKindOfClass:[NSHTTPURLResponse class]])
			{
				NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
				NSDictionary *headers = [httpResponse allHeaderFields];
				
				NSInteger statusCode = [httpResponse statusCode];
				if (statusCode==200)
				{
 					NSString *contentType = [headers objectForKey:@"Content-Type"];
					
					if ([contentType isEqualToString:@"application/x-gzip"])
					{
						NSData *decompressed = [data gzipInflate];
						NSString *decompStr = [[[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSASCIIStringEncoding] autorelease];
						
						NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:decompStr, @"Text", account, @"Account", nil];
						
						[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromDict:) withObject:tmpDict waitUntilDone:YES];
					}
					else 
					{
						NSLog(@"Got Content Type: %@", contentType);
						sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
						NSLog(@"%@", sourceSt);
					}
				}
				else
				{
					NSLog(@"Got status code %d", statusCode);
				}
			}
			
		}
	}
	
	
	// select week options
	
	URL = [@"https://itts.apple.com" stringByAppendingString:post_url];		  
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	postBody = [NSMutableData data];
	body = [NSString stringWithFormat:@"%@=Summary&%@=Weekly&hiddenDayOrWeekSelection=Weekly&hiddenSubmitTypeName=ShowDropDown&wosid=%@", selReportType, selDateType, wosid];
	
	[postBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
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
		[self setStatusError:@"No week options found"];
		return;
	}
	
	
	selectSearchRange = NSMakeRange(selectRange.location, [sourceSt length] - selectRange.location);
	endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:selectSearchRange];

	selectString = [sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)];
	NSArray *weekOptions = [selectString optionsFromSelect];
	dayorweekdropdownName = [[selectString dictionaryOfAttributesFromTag] objectForKey:@"name"];	
	selReportType = [sourceSt nameForTag:@"select" WithID:@"selReportType"];
	selDateType = [sourceSt nameForTag:@"select" WithID:@"selDateType"];
	
	
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
										timeoutInterval:60.0];
			
			[request setHTTPMethod:@"POST"];
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
			
			//create the body
			postBody = [NSMutableData data];
			NSString *body = [NSString stringWithFormat:@"%@=Summary&%@=Weekly&%@=%@&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=Download&wosid=%@", selReportType, selDateType, dayorweekdropdownName, formDate, formDate, wosid];
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
				[self setStatusError:@"No data received from request week report"];
				return;
			}
			
			if ([response isKindOfClass:[NSHTTPURLResponse class]])
			{
				NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
				NSDictionary *headers = [httpResponse allHeaderFields];
				
				NSInteger statusCode = [httpResponse statusCode];
				if (statusCode==200)
				{
 					NSString *contentType = [headers objectForKey:@"Content-Type"];
					
					if ([contentType isEqualToString:@"application/x-gzip"])
					{
						NSData *decompressed = [data gzipInflate];
						NSString *decompStr = [[[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSASCIIStringEncoding] autorelease];
						
						NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:decompStr, @"Text", account, @"Account", nil];
						
						[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromDict:) withObject:tmpDict waitUntilDone:YES];
					}
					else 
					{
						NSLog(@"Got Content Type: %@", contentType);
						sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
						NSLog(@"%@", sourceSt);
						
					}
				}
				else
				{
					NSLog(@"Got status code %d", statusCode);
				}
			}
		}
	}	
	
	// select week options
	
	URL = [@"https://itts.apple.com" stringByAppendingString:post_url];		  
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	postBody = [NSMutableData data];
	body = [NSString stringWithFormat:@"%@=Summary&%@=Monthly%%20Free&hiddenDayOrWeekSelection=Monthly%%20Free&hiddenSubmitTypeName=ShowDropDown&wosid=%@", selReportType, selDateType, wosid];
	
	[postBody appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
	
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
	
	selectSearchRange = NSMakeRange(selectRange.location, [sourceSt length] - selectRange.location);
	endSelectRange = [sourceSt rangeOfString:@"</select>" options:NSLiteralSearch range:selectSearchRange];
	
	selectString = [sourceSt substringWithRange:NSMakeRange(selectRange.location, endSelectRange.location - selectRange.location + endSelectRange.length)];
	NSArray *monthlyFreeOptions = [selectString optionsFromSelect];
	dayorweekdropdownName = [[selectString dictionaryOfAttributesFromTag] objectForKey:@"name"];	
	selReportType = [sourceSt nameForTag:@"select" WithID:@"selReportType"];
	selDateType = [sourceSt nameForTag:@"select" WithID:@"selDateType"];
	
	//NSLog(@"%@", sourceSt);
	
	
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
										timeoutInterval:60.0];
			
			[request setHTTPMethod:@"POST"];
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
			
			//create the body
			postBody = [NSMutableData data];
			NSString *body = [NSString stringWithFormat:@"%@=Summary&%@=Monthly%%20Free&%@=%@&hiddenDayOrWeekSelection=%@&hiddenSubmitTypeName=Download&wosid=%@", selReportType, selDateType, dayorweekdropdownName, formDate, formDate, wosid];
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
			
			if ([response isKindOfClass:[NSHTTPURLResponse class]])
			{
				NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
				NSDictionary *headers = [httpResponse allHeaderFields];
				
				NSInteger statusCode = [httpResponse statusCode];
				if (statusCode==200)
				{
 					NSString *contentType = [headers objectForKey:@"Content-Type"];
					
					if ([contentType isEqualToString:@"application/x-gzip"])
					{
						NSData *decompressed = [data gzipInflate];
						NSString *decompStr = [[[NSString alloc] initWithBytes:[decompressed bytes] length:[decompressed length] encoding:NSASCIIStringEncoding] autorelease];
						
						NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:decompStr, @"Text", untilDate, @"UntilDate", fromDate, @"FromDate", account, @"Account", nil];
						
						[DB performSelectorOnMainThread:@selector(insertMonthlyFreeReportFromFromDict:) withObject:tmpDict waitUntilDone:YES];
					}
					else 
					{
						/*
						 NSLog(@"Got Content Type: %@", contentType);
						 sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
						 NSLog(@"%@", sourceSt);
						 */
						
						// no free transactions to report
						
						NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:untilDate, @"UntilDate", fromDate, @"FromDate", account, @"Account", nil];
						[DB performSelectorOnMainThread:@selector(insertMonthlyFreeReportFromFromDict:) withObject:tmpDict waitUntilDone:YES];
						
						
					}
				}
				else
				{
					NSLog(@"Got status code %d", statusCode);
				}
			}			
		}
		
	}	
	
	if (!financialUrl) 
	{
		if (alternateLogin)
		{
			[self setStatusSuccess:@"Synchronization via ITTS Done"];
		}
		else
		{
			[self setStatusError:@"No link to financial reports"];
			return;
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
	
	//NSLog(@"%@", sourceSt);
	
	
	
	// switch to earnings tab
	
	NSDictionary *formAttributes = [sourceSt dictionaryOfAttributesForTag:@"form" WithName:@"mainForm"];
	post_url = [formAttributes objectForKey:@"action"];
	
	NSDictionary *earningsInput = [sourceSt dictionaryForInputInForm:@"mainForm" withID:@"Earnings"];
	NSString *earningsName = [earningsInput objectForKey:@"name"];
	
	NSArray *values = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Earnings" forKey:earningsName]];
	NSString *bodyString = [NSString bodyForFormPostWithType:FormPostTypeMultipart valueDictionaries:values];
	NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	URL = [@"https://itunesconnect.apple.com" stringByAppendingString:post_url];
	
	request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestUseProtocolCachePolicy
								timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [NSString multipartBoundaryString]] forHTTPHeaderField: @"Content-Type"];
	[request addValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_1; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9" forHTTPHeaderField:@"User-Agent"];
	
	[request setHTTPBody:bodyData];
	
	[self setStatus:@"Going to Earnings Tab"];
	
	data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received (vendor selection)"];
		return;
	}
	
	sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	formAttributes = [sourceSt dictionaryOfAttributesForTag:@"form" WithName:@"mainForm"];
	post_url = [formAttributes objectForKey:@"action"];
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"class = 'values'"];
	NSArray *array = [sourceSt arrayOfHTMLForTags:@"tr" matchingPredicate:pred];
	
	// get month/year, region and submit name for each
	NSPredicate *firstPred = [NSPredicate predicateWithFormat:@"class = 'col-1 first'"];
	NSPredicate *secondPred = [NSPredicate predicateWithFormat:@"class = 'col-2'"];
	
	NSArray *selects = [sourceSt arrayOfHTMLForTags:@"select" matchingPredicate:nil];
	
	// should be 3
	NSPredicate *selectedPredicate = [NSPredicate predicateWithFormat:@"selected = 'selected'"];
	
	
	NSString *regionSelect = [selects objectAtIndex:0];
	NSString *regionSelectName = [[regionSelect dictionaryOfAttributesFromTag] objectForKey:@"name"];
	NSArray *regionArray = [regionSelect arrayOfTags:@"option"];
	
	NSString *selectedRegionValue = [[regionArray objectAtIndex:0] objectForKey:@"value"];
	
	NSString *monthSelect = [selects objectAtIndex:1];
	NSString *monthSelectName = [[monthSelect dictionaryOfAttributesFromTag] objectForKey:@"name"];
	NSString *selectedMonthValue = [[[monthSelect arrayOfTags:@"option" matchingPredicate:selectedPredicate] lastObject] objectForKey:@"value"];
	
	NSString *yearSelect = [selects objectAtIndex:2];
	NSString *yearSelectName = [[yearSelect dictionaryOfAttributesFromTag] objectForKey:@"name"];
	NSString *selectedYearValue = [[[yearSelect arrayOfTags:@"option" matchingPredicate:selectedPredicate] lastObject] objectForKey:@"value"];
	
	for (NSString *trString in array)
	{
		NSString *monthYear = [[[trString arrayOfHTMLForTags:@"td" matchingPredicate:firstPred] lastObject] innerText];
		NSString *region = [[[trString arrayOfHTMLForTags:@"td" matchingPredicate:secondPred] lastObject] innerText];
		
		NSString *submitName = [[[trString arrayOfInputs] lastObject] objectForKey:@"name"];
		
		NSDate *reportDate = [self reportDateFromString:monthYear];
		ReportRegion reportRegion = [self regionFromString:region];
		
		if ([self needToDownloadFinancialReportWithDate:reportDate region:reportRegion])
		{
			NSArray *postValues = [NSArray arrayWithObjects:
								   [NSDictionary dictionaryWithObject:selectedRegionValue forKey:regionSelectName],
								   [NSDictionary dictionaryWithObject:selectedMonthValue forKey:monthSelectName],
								   [NSDictionary dictionaryWithObject:selectedYearValue forKey:yearSelectName],
								   [NSDictionary dictionaryWithObject:@"10" forKey:[submitName stringByAppendingString:@".x"]],
								   [NSDictionary dictionaryWithObject:@"5" forKey:[submitName stringByAppendingString:@".y"]], nil];
			
			NSString *bodyString = [NSString bodyForFormPostWithType:FormPostTypeMultipart valueDictionaries:postValues];
			
			NSLog(@"%d, %@", [bodyString length], bodyString);
			
			NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
			
			URL = [@"https://itunesconnect.apple.com" stringByAppendingString:post_url];
			
			
			//URL = [@"http://www.drobnik.com" stringByAppendingString:post_url];
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestUseProtocolCachePolicy
										timeoutInterval:60.0];
			[request setHTTPMethod:@"POST"];
			[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [NSString multipartBoundaryString]] forHTTPHeaderField: @"Content-Type"];
			[request addValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_1; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9" forHTTPHeaderField:@"User-Agent"];
			
			[request setHTTPBody:bodyData];
			
			[self setStatus:[NSString stringWithFormat:@"Loading %@ %@", monthYear, region]];
			
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			if (error)
			{
				[self setStatusError:[error localizedDescription]];
				return;
			}
			
			if (!data) 
			{
				[self setStatusError:@"No data received for report"];
				return;
			}
			
			
			sourceSt = [[[NSString alloc] initWithData:[data gzipInflate] encoding:NSUTF8StringEncoding] autorelease];
			
			NSLog(@"%@", sourceSt);
			
			NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:sourceSt, @"Text", account, @"Account", [NSNumber numberWithInt:reportRegion], @"Region", reportDate, @"FallbackDate", [NSNumber numberWithInt:ReportTypeFinancial], @"Type", nil];
			
			[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromDict:) withObject:tmpDict waitUntilDone:YES];
			
			financialsDownloaded++;
		}
	}
	
	
	
	
	/*
	
	NSString *nextUrl = [sourceSt hrefForLinkContainingText:@"rt-OSarw.gif"];
	
	NSArray *reportURLs = [sourceSt arrayWithHrefDicts];
	
	for (NSDictionary *oneDict in reportURLs)
	{
		NSString *url = [oneDict objectForKey:@"url"];
		NSString *text = [oneDict objectForKey:@"contents"];
		
		ReportRegion region;
		int month;
		int year;
		
		if ([text hasSuffix:@".txt"]&&[self needToDownloadFinancialReportWithFilename:text region:&region month:&month year:&year])
		{
			NSDate *fallbackDate = [NSDate dateFromMonth:month Year:2000+year];
			
			
			URL = [@"https://itunesconnect.apple.com" stringByAppendingString:url];
			
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestUseProtocolCachePolicy
										timeoutInterval:60.0];  // might take long
			
			[request setHTTPMethod:@"GET"];
			
			
			[self setStatus:[@"Loading " stringByAppendingString:text]];
			
			financialsDownloaded++;
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
			
			NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:sourceSt, @"Text", account, @"Account", [NSNumber numberWithInt:region], @"Region", fallbackDate, @"FallbackDate", [NSNumber numberWithInt:ReportTypeFinancial], @"Type", nil];
			
			[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromDict:) withObject:tmpDict waitUntilDone:YES];
			
		}
	}
	
	
	
	NSInteger ReportPage = 0;
	// to to next page if possible and if we at least downloaded one report on first page
	while ((!ReportPage||financialsDownloaded)&&nextUrl)
	{
		ReportPage ++;
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
			
			ReportRegion region;
			int month;
			int year;
			if ([text hasSuffix:@".txt"]&&[self needToDownloadFinancialReportWithFilename:text region:&region month:&month year:&year])
			{
				NSDate *fallbackDate = [NSDate dateFromMonth:month Year:2000+year];
				URL = [@"https://itunesconnect.apple.com" stringByAppendingString:url];
				
				request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
												cachePolicy:NSURLRequestUseProtocolCachePolicy
											timeoutInterval:60.0];  // might take long
				
				[request setHTTPMethod:@"GET"];
				
				
				[self setStatus:[@"Loading " stringByAppendingString:text]];
				
				data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
				financialsDownloaded++;
				
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
				
				NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:sourceSt, @"Text", account, @"Account", [NSNumber numberWithInt:region], @"Region", fallbackDate, @"FallbackDate", [NSNumber numberWithInt:ReportTypeFinancial], @"Type", nil];
				
				[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromDict:) withObject:tmpDict waitUntilDone:YES];
				
			}
		}
	}
	
	*/
	
	
	
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
