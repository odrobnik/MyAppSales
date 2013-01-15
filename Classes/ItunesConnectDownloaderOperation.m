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

#import "NSString+AJAX.h"
#import "NSURLRequest+AJAX.h"


@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end


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
	else if ([regionCode isEqualToString:@"MX"]) region = ReportRegionMexico;
	else if ([regionCode isEqualToString:@"CH"]) region = ReportRegionSwitzerland;
	else if ([regionCode isEqualToString:@"NO"]) region = ReportRegionNorway;
	else if ([regionCode isEqualToString:@"NZ"]) region = ReportRegionNewZealand;
    else if ([regionCode isEqualToString:@"CN"]) region = ReportRegionChina;
    else if ([regionCode isEqualToString:@"DK"]) region = ReportRegionDenmark;
    else if ([regionCode isEqualToString:@"SE"]) region = ReportRegionSweden;
    else if ([regionCode isEqualToString:@"SG"]) region = ReportRegionSingapore;
    else if ([regionCode isEqualToString:@"HK"]) region = ReportRegionHongKong;
    else if ([regionCode isEqualToString:@"TW"]) region = ReportRegionTaiwan;
    else if ([regionCode isEqualToString:@"RU"]) region = ReportRegionRussia;
    else if ([regionCode isEqualToString:@"TR"]) region = ReportRegionTurkey;
    else if ([regionCode isEqualToString:@"IN"]) region = ReportRegionIndia;
    else if ([regionCode isEqualToString:@"ID"]) region = ReportRegionIndonesia;
    else if ([regionCode isEqualToString:@"IL"]) region = ReportRegionIsrael;
    else if ([regionCode isEqualToString:@"SA"]) region = ReportRegionSaudiArabia;
    else if ([regionCode isEqualToString:@"ZA"]) region = ReportRegionSouthAfrica;
    else if ([regionCode isEqualToString:@"AE"]) region = ReportRegionUnitedArabEmirates;
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
	
	if ([string isEqualToString:@"Mexico"])
	{
		return ReportRegionMexico;
	}
	if ([string isEqualToString:@"Norway"])
	{
		return ReportRegionNorway;
	}
	if ([string isEqualToString:@"New Zealand"])
	{
		return ReportRegionNewZealand;
	}
	if ([string isEqualToString:@"Switzerland"])
	{
		return ReportRegionSwitzerland;
	}
    if ([string isEqualToString:@"China"])
	{
		return ReportRegionChina;
	}
	if ([string isEqualToString:@"Denmark"])
	{
		return ReportRegionDenmark;
	}
	if ([string isEqualToString:@"Sweden"])
	{
		return ReportRegionSweden;
	}
    if ([string isEqualToString:@"Singapore"])
	{
		return ReportRegionSingapore;
	}
    if ([string isEqualToString:@"Hong Kong"])
	{
		return ReportRegionHongKong;
	}
    if ([string isEqualToString:@"Taiwan"])
	{
		return ReportRegionTaiwan;
	}

    
	return ReportRegionUnknown;
}

- (NSDate *)reportDateFromString:(NSString *)string
{
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
	[formatter setDateFormat:@"MMM y"];
	[formatter setLocale:usLocale];
	
	NSDate *retDate = [formatter dateFromString:string];
	
	NSAssert1(retDate, @"Could not parse date '%@'", string);
	return [formatter dateFromString:string];
}

- (NSDate *)reportDateFromShortDate:(NSString *)string
{
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
	[formatter setDateFormat:@"MM/dd/yyyy"];
	[formatter setLocale:usLocale];
	
	NSDate *retDate = [formatter dateFromString:string];
	
	NSAssert1(retDate, @"Could not parse date '%@'", string);
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

- (void)loadSalesReportsAtURL:(NSURL *)url
{
    // GET reportingitc.apple.com
    
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url
														 cachePolicy:NSURLRequestReloadIgnoringCacheData
													 timeoutInterval:60.0];	
	NSURLResponse* response = nil; 
	NSError* error = nil;
	
	[self setStatus:@"Opening Sales & Trends (1)"];	
	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from Sales & Trends (1)"];
		return;
	}
	
	NSString *html = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	NSURL *baseURL = [NSURL URLWithString:@"https://reportingitc.apple.com/"];
	
	// check if vendor selection is necessary
	if ([html rangeOfString:@"Choose Vendor"].length)
	{
		// make a post so that we get the vendor ids
		request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://reportingitc.apple.com/jsp/providerselection.faces"]
										cachePolicy:NSURLRequestReloadIgnoringCacheData
									timeoutInterval:60.0];	
		[request setHTTPMethod:@"POST"];
		
		[self setStatus:@"Selecting Vendor (2)"];
        
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (error)
		{
			[self setStatusError:[error localizedDescription]];
			return;
		}
		
		if (!data) 
		{
			[self setStatusError:@"No data received from Vendor Selection"];
			return;
		}
		
		NSString *divHtml = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
		
		NSPredicate *vendorPred = [NSPredicate predicateWithFormat:@"class = 'vendor'"];
		NSArray *vendorOptions = [divHtml arrayOfHTMLForTags:@"div" matchingPredicate:vendorPred];
		
		NSMutableArray *vendors = [NSMutableArray array];
		
		for (NSString *oneVendorDiv in vendorOptions)
		{
			NSScanner *scanner = [NSScanner scannerWithString:oneVendorDiv];
			[scanner scanUpToString:@"setVendorNumber(" intoString:NULL];
			
			if ([scanner scanString:@"setVendorNumber(" intoString:NULL])
			{
				NSInteger vendorID = 0;
				NSString *vendorName = nil;
				
				[scanner scanInteger:&vendorID];
				[scanner scanString:@",'" intoString:NULL];
				[scanner scanUpToString:@"');" intoString:&vendorName];
				
				if (vendorName && vendorID)
				{
					NSDictionary *vendor = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:vendorID], @"VendorID",
											vendorName, @"VendorName", nil];
					
					[vendors addObject:vendor];
				}
				else 
				{
					NSLog(@"Cannot parse vendor from string '%@'", oneVendorDiv);
				}
			}
		}
		
		// get the highest vendor
		NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"VendorID" ascending:YES];
		NSArray *sortedVendors = [vendors sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
		
		NSDictionary *bestVendor = [sortedVendors lastObject];
		
		html = [html stringByReplacingOccurrencesOfString:@":param1," withString:[NSString stringWithFormat:@":'%@'", [bestVendor objectForKey:@"VendorID"]]];
		html = [html stringByReplacingOccurrencesOfString:@":param2," withString:[NSString stringWithFormat:@":'%@'", [bestVendor objectForKey:@"VendorName"]]];
		
		NSString *viewState = [html ajaxViewState];
		NSArray *ajaxParams= [html parametersFromAjaxSubmitString];
		
		NSURL *baseURL = [NSURL URLWithString:@"https://reportingitc.apple.com/"];
		
		NSURLRequest *ajaxRequest = [NSURLRequest ajaxRequestWithParameters:ajaxParams viewState:viewState baseURL:baseURL];
		
		data = [NSURLConnection sendSynchronousRequest:ajaxRequest returningResponse:&response error:&error];
		
		if (error)
		{
			[self setStatusError:[error localizedDescription]];
			return;
		}
		
		if (!data) 
		{
			[self setStatusError:@"No data received from Vendor Selection (2)"];
			return;
		}
		
		html = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
		
		if (![html rangeOfString:@"Ajax-Response\" content=\"redirect"].length)
		{
			[self setStatusError:@"Error going to Sales & Trends"];
			return;
		}
	}
	else 
	{
		// ----- execute embedded AJAX reload
		NSArray *ajaxParams= [html parametersFromAjaxSubmitString];
		NSString *viewState = [html ajaxViewState];
		
		NSURLRequest *ajaxRequest = [NSURLRequest ajaxRequestWithParameters:ajaxParams viewState:viewState baseURL:baseURL];
		
		[self setStatus:@"Opening Sales & Trends (2)"];
		
		data = [NSURLConnection sendSynchronousRequest:ajaxRequest returningResponse:&response error:&error];
		
		if (error)
		{
			[self setStatusError:[error localizedDescription]];
			return;
		}
		
		if (!data) 
		{
			[self setStatusError:@"No data received from Sales & Trends (2)"];
			return;
		}
		
		html = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
		
		if (![html rangeOfString:@"Ajax-Response\" content=\"redirect"].length)
		{
			[self setStatusError:@"Error going to Sales & Trends"];
			return;
		}
		
	}
	
	// ---- Switching to sales face
	
	url = [NSURL URLWithString:@"/sales.faces" relativeToURL:baseURL];
	
	request=[NSMutableURLRequest requestWithURL:url
									cachePolicy:NSURLRequestReloadIgnoringCacheData
								timeoutInterval:60.0];	
	
	[self setStatus:@"Opening Sales & Trends (3)"];
	
	data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from Sales & Trends (3)"];
		return;
	}
	
	html = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
    
	NSString *viewState = [html ajaxViewState];
    
    //some reused variables
    NSArray *ajaxParams = nil;
    NSURLRequest *ajaxRequest = nil;
    NSString *extraFormString = nil;
    NSString* bodyString = nil;
    NSData* bodyData = nil;
	
	// get first elements from day and week selections
	NSPredicate *datePred = [NSPredicate predicateWithFormat:@"name = 'theForm:datePickerSourceSelectElementSales'"];
	NSArray *dayOptions = [html arrayOfHTMLForTags:@"select" matchingPredicate:datePred];
	if ([dayOptions count]==1)
	{
		dayOptions = [[dayOptions objectAtIndex:0] optionsFromSelect];
	}
	
	
	NSPredicate *weekPred = [NSPredicate predicateWithFormat:@"name = 'theForm:weekPickerSourceSelectElement'"];
	NSArray *weekOptions = [html arrayOfHTMLForTags:@"select" matchingPredicate:weekPred];
	if ([weekOptions count]==1)
	{
		weekOptions = [[weekOptions objectAtIndex:0] optionsFromSelect];
	}
	
	//----- execute onLoad
	extraFormString = [NSString stringWithFormat:@"theForm%%3AuserType=notnormal&theForm%%3AvendorType=Y&theForm%%3AdateType=D&theForm%%3AoptInVar=A&theForm%%3AcontentType=iOS&theForm%%3AcontentSubType=Paid%%20Apps&=&theForm%%3AdatePickerSourceSelectElementSales=%@&theForm%%3AweekPickerSourceSelectElement=%@",
                       [[dayOptions objectAtIndex:0] stringByUrlEncoding],
                       [[weekOptions objectAtIndex:0] stringByUrlEncoding]];
	
	
	ajaxParams = [html parametersFromAjaxSubmitStringForFunction:@"onLoad"];
	ajaxRequest = [NSURLRequest ajaxRequestWithParameters:ajaxParams extraFormString:extraFormString viewState:viewState baseURL:baseURL];
	
	[self setStatus:@"Accessing Sales"];
	
	data = [NSURLConnection sendSynchronousRequest:ajaxRequest returningResponse:&response error:&error];
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from Sales & Trends"];
		return;
	}
    
	viewState = [html ajaxViewState];
	
	NSString *pickerAjax = [html tagHTMLforTag:@"select" WithID:@"theForm:datePickerSourceSelectElementSales"];
	ajaxParams = [html parametersFromAjaxSubmitStringForFunction:@"onLoad"];//[pickerAjax parametersFromAjaxSubmitString];
	
	NSString *weekPickerAjax = [html tagHTMLforTag:@"select" WithID:@"theForm:weekPickerSourceSelectElement"];
	NSArray *weekAjaxParams = [weekPickerAjax parametersFromAjaxSubmitString];
	
	NSRange range = [html rangeOfString:@" id=\"weeklyLabel\""];
	NSString *weekSwitchHTML = [html substringFromIndex:range.location];
	NSArray *weekSwitchAjaxParams = [weekSwitchHTML parametersFromAjaxSubmitString]; // has extra at the end, but we ignore that

	//----- download DAILY
	for (NSString *oneDayOption in dayOptions)
	{
		NSDate *reportDate = [self reportDateFromShortDate:oneDayOption];
		
		if (![reportsToIgnore reportBySearchingForDate:reportDate type:ReportTypeDay region:ReportRegionUnknown])
		{
			//NSInteger index = [dayOptions indexOfObject:oneDayOption];
			
			//if (index)
			{
				// -----switch daily report date via AJAX
                NSString *extraFormString2 = [NSString stringWithFormat:@"theForm%%3AvendorType=Y&=&theForm%%3AdatePickerSourceSelectElementSales=%@&theForm%%3AweekPickerSourceSelectElement=%@",
											 [oneDayOption stringByUrlEncoding],
											 [[weekOptions objectAtIndex:0] stringByUrlEncoding]];
				
				ajaxRequest = [NSURLRequest ajaxRequestWithParameters:ajaxParams extraFormString:extraFormString2 viewState:viewState baseURL:baseURL];
				
				data = [NSURLConnection sendSynchronousRequest:ajaxRequest returningResponse:&response error:&error];
				
				if (error)
				{
					[self setStatusError:[error localizedDescription]];
					return;
				}
				
				if (!data) 
				{
					[self setStatusError:@"No data received from Sales & Trends"];
					return;
				}
				
				viewState = [html ajaxViewState];
			}
			
			
			url = [NSURL URLWithString:@"/sales.faces" relativeToURL:baseURL];
			
			request=[NSMutableURLRequest requestWithURL:url
											cachePolicy:NSURLRequestReloadIgnoringCacheData
										timeoutInterval:60.0];	
			
			bodyString = [NSString stringWithFormat:@"theForm=theForm&theForm%%3AuserType=notnormal&theForm%%3AvendorType=Y&theForm%%3AdateType=D&theForm%%3AoptInVar=A&theForm%%3AcontentType=iOS&theForm%%3AcontentSubType=Paid%%20Apps&theForm%%3AdatePickerSourceSelectElementSales=%@&theForm%%3AweekPickerSourceSelectElement=%@&javax.faces.ViewState=%@&theForm%%3AdownloadLabel2=theForm%%3AdownloadLabel2&",
						  [oneDayOption stringByUrlEncoding],
						  [[weekOptions objectAtIndex:0] stringByUrlEncoding],
						  [viewState stringByUrlEncoding] ];
			bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
			
			[request setHTTPMethod:@"POST"];
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
			
			[request setHTTPBody:bodyData];
			
			[self setStatus:[NSString stringWithFormat:@"Loading Day Report for %@", oneDayOption]];
			
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			if (error)
			{
				[self setStatusError:[error localizedDescription]];
				return;
			}
			
			if (!data) 
			{
				[self setStatusError:@"No data received from Sales face"];
				return;
			}
			
			if ([[response MIMEType] isEqualToString:@"application/a-gzip"])
			{
				NSString *reportText = [[[NSString alloc] initWithData:[data gzipInflate] encoding:NSUTF8StringEncoding] autorelease];
				
				NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:reportText, @"Text", account, @"Account", reportDate, @"FallbackDate", [NSNumber numberWithInt:ReportTypeDay], @"Type", nil];
				
				[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromDict:) withObject:tmpDict waitUntilDone:YES];
				
			}
		}
	}
	
	// ----- switch to weekly so that we get the viewstate for weekly
	
	extraFormString = [NSString stringWithFormat:@"theForm%%3AuserType=notnormal&theForm%%3AvendorType=Y&theForm%%3AdateType=W&theForm%%3AoptInVar=A&theForm%%3AcontentType=iOS&theForm%%3AcontentSubType=Paid%%20Apps&=&theForm%%3AdatePickerSourceSelectElementSales=%@&theForm%%3AweekPickerSourceSelectElement=%@",
					   [[dayOptions objectAtIndex:0] stringByUrlEncoding],
					   [[dayOptions objectAtIndex:0] stringByUrlEncoding]];
	
	ajaxRequest = [NSURLRequest ajaxRequestWithParameters:weekSwitchAjaxParams extraFormString:extraFormString viewState:viewState baseURL:baseURL];
	
	[self setStatus:@"Switching to Weekly"];
	
	data = [NSURLConnection sendSynchronousRequest:ajaxRequest returningResponse:&response error:&error];
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		[self setStatusError:@"No data received from Weekly"];
		return;
	}
	
	html = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
	
	viewState = [html ajaxViewState];	
	
	//----- download WEEKLY
	for (NSString *oneWeekOption in weekOptions)
	{
		NSDate *reportDate = [self reportDateFromShortDate:oneWeekOption];
		
		if (![reportsToIgnore reportBySearchingForDate:reportDate type:ReportTypeWeek region:ReportRegionUnknown])
		{
			//NSInteger index = [weekOptions indexOfObject:oneWeekOption];
			
			//if (index)
			{
				// -----switch weekly report screen via AJAX
				
				NSString *extraFormString = [NSString stringWithFormat:@"theForm%%3AvendorType=Y&=&theForm%%3AdatePickerSourceSelectElementSales=%@&theForm%%3AweekPickerSourceSelectElement=%@",
											 [[dayOptions objectAtIndex:0] stringByUrlEncoding],
											 [oneWeekOption stringByUrlEncoding]];
				
				
				ajaxRequest = [NSURLRequest ajaxRequestWithParameters:weekSwitchAjaxParams extraFormString:extraFormString viewState:viewState baseURL:baseURL];
				
				data = [NSURLConnection sendSynchronousRequest:ajaxRequest returningResponse:&response error:&error];
				
				if (error)
				{
					[self setStatusError:[error localizedDescription]];
					return;
				}
				
				if (!data) 
				{
					[self setStatusError:@"No data received from Weeks"];
					return;
				}
				
				viewState = [html ajaxViewState];
			}
			
			
			url = [NSURL URLWithString:@"/sales.faces" relativeToURL:baseURL];
			
			request=[NSMutableURLRequest requestWithURL:url
											cachePolicy:NSURLRequestReloadIgnoringCacheData
										timeoutInterval:60.0];	
			
			bodyString = [NSString stringWithFormat:@"theForm=theForm&theForm%%3AuserType=notnormal&theForm%%3AvendorType=Y&theForm%%3AdateType=W&theForm%%3AoptInVar=A&theForm%%3AdatePickerSourceSelectElementSales=%@&theForm%%3AweekPickerSourceSelectElement=%@&javax.faces.ViewState=%@&theForm%%3AdownloadLabel2=theForm%%3AdownloadLabel2",
						  [[dayOptions objectAtIndex:0] stringByUrlEncoding],
						  [oneWeekOption stringByUrlEncoding],
						  [viewState stringByUrlEncoding] ];
			bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
			
			[request setHTTPMethod:@"POST"];
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
			
			[request setHTTPBody:bodyData];
			
			[self setStatus:[NSString stringWithFormat:@"Loading Week Report for %@", oneWeekOption]];
			
			data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			if (error)
			{
				[self setStatusError:[error localizedDescription]];
				return;
			}
			
			if (!data) 
			{
				[self setStatusError:@"No data received from Sales face"];
				return;
			}
			
			if ([[response MIMEType] isEqualToString:@"application/a-gzip"])
			{
				NSString *reportText = [[[NSString alloc] initWithData:[data gzipInflate] encoding:NSUTF8StringEncoding] autorelease];
				
				NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:reportText, @"Text", account, @"Account", reportDate, @"FallbackDate", [NSNumber numberWithInt:ReportTypeDay], @"Type", nil];
				
				[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromDict:) withObject:tmpDict waitUntilDone:YES];
			}
		}
	}	
}





- (void) main
{
	[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"reportingitc.apple.com"];
	[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"itunesconnect.apple.com"];
	
	
	
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
	NSString *salesUrl = nil;
	
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
		salesUrl = [sourceSt hrefForLinkContainingText:@"Sales"];
		
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
	
	NSURL *baseURL = [NSURL URLWithString:@"https://itunesconnect.apple.com"];
	[self loadSalesReportsAtURL:[NSURL URLWithString:salesUrl relativeToURL:baseURL]];
	
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
	
	
	// a set to keep track of already downloaded financial reports (the partially repeat on following pages)
	NSMutableSet *downloadedFinancialReports = [NSMutableSet set];
	
	do 
	{
		financialsDownloaded=0;
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
		
		NSPredicate *showPredicate = [NSPredicate predicateWithFormat:@"src = '/itc/images/btn-white-show.png'"];
		NSString *showPeriodButtonName = [[[sourceSt arrayOfTags:@"input" matchingPredicate:showPredicate] lastObject] objectForKey:@"name"];
		
		for (NSString *trString in array)
		{
			NSString *monthYear = [[[trString arrayOfHTMLForTags:@"td" matchingPredicate:firstPred] lastObject] innerText];
			NSString *region = [[[trString arrayOfHTMLForTags:@"td" matchingPredicate:secondPred] lastObject] innerText];
			
			NSString *submitName = [[[trString arrayOfInputs] lastObject] objectForKey:@"name"];
			
			// region is nil if there are no monthly reports
			if (region&&submitName)
			{
				NSString *financialReportKey = [monthYear stringByAppendingString:region];
				
				NSDate *reportDate = [self reportDateFromString:monthYear];
				ReportRegion reportRegion = [self regionFromString:region];
				
				if (![downloadedFinancialReports containsObject:financialReportKey]&&[self needToDownloadFinancialReportWithDate:reportDate region:reportRegion])
				{
					NSArray *postValues = [NSArray arrayWithObjects:
										   [NSDictionary dictionaryWithObject:selectedRegionValue forKey:regionSelectName],
										   [NSDictionary dictionaryWithObject:selectedMonthValue forKey:monthSelectName],
										   [NSDictionary dictionaryWithObject:selectedYearValue forKey:yearSelectName],
										   [NSDictionary dictionaryWithObject:@"10" forKey:[submitName stringByAppendingString:@".x"]],
										   [NSDictionary dictionaryWithObject:@"5" forKey:[submitName stringByAppendingString:@".y"]], nil];
					
					NSString *bodyString = [NSString bodyForFormPostWithType:FormPostTypeMultipart valueDictionaries:postValues];
					
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
					
					NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:sourceSt, @"Text", account, @"Account", [NSNumber numberWithInt:reportRegion], @"Region", reportDate, @"FallbackDate", [NSNumber numberWithInt:ReportTypeFinancial], @"Type", nil];
					
					[[Database sharedInstance] performSelectorOnMainThread:@selector(insertReportFromDict:) withObject:tmpDict waitUntilDone:YES];
					
					financialsDownloaded++;
					
					[downloadedFinancialReports addObject:financialReportKey];
				}
			}
		}
		
		
		// go to earlier month page
		
		NSUInteger monthIndex = [selectedMonthValue intValue];
		NSUInteger yearIndex = [selectedYearValue intValue];
		
		if (monthIndex>0)
		{
			monthIndex--;
		}
		else if (yearIndex>0)
		{
			monthIndex=11;
			yearIndex--;
		}
		else 
		{
			// no more pages left
			financialsDownloaded = 0;
		}
		
		if (financialsDownloaded)
		{
			
			selectedMonthValue = [NSString stringWithFormat:@"%d", monthIndex];
			selectedYearValue = [NSString stringWithFormat:@"%d", yearIndex];
			
			
			
			NSArray *postValues = [NSArray arrayWithObjects:
								   [NSDictionary dictionaryWithObject:selectedRegionValue forKey:regionSelectName],
								   [NSDictionary dictionaryWithObject:selectedMonthValue forKey:monthSelectName],
								   [NSDictionary dictionaryWithObject:selectedYearValue forKey:yearSelectName],
								   [NSDictionary dictionaryWithObject:@"10" forKey:[showPeriodButtonName stringByAppendingString:@".x"]],
								   [NSDictionary dictionaryWithObject:@"5" forKey:[showPeriodButtonName stringByAppendingString:@".y"]], nil];
			
			bodyString = [NSString bodyForFormPostWithType:FormPostTypeMultipart valueDictionaries:postValues];
			
			bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
			
			URL = [@"https://itunesconnect.apple.com" stringByAppendingString:post_url];
			
			
			//URL = [@"http://www.drobnik.com" stringByAppendingString:post_url];
			request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
											cachePolicy:NSURLRequestUseProtocolCachePolicy
										timeoutInterval:60.0];
			[request setHTTPMethod:@"POST"];
			[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [NSString multipartBoundaryString]] forHTTPHeaderField: @"Content-Type"];
			[request addValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_1; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9" forHTTPHeaderField:@"User-Agent"];
			
			[request setHTTPBody:bodyData];
			
			//[self setStatus:[NSString stringWithFormat:@"Loading %@ %@", monthYear, region]];
			
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
			
			sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
		}
	} 
	while (financialsDownloaded);
	
	[self setStatusSuccess:@"Synchronization Done"];
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
