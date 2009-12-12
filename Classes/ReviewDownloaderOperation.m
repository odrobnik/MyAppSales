//
//  ReviewDownloaderOperation.m
//  ASiST
//
//  Created by Oliver on 13.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "ReviewDownloaderOperation.h"
#import "NSDictionary+Helpers.h"
#import "Review.h"
#import "App.h"
#import "Country.h"


@interface ReviewDownloaderOperation ()
- (void) sendFinishToDelegate;
@end;



@implementation ReviewDownloaderOperation

@synthesize app, country, delegate;


- (id) initForApp:(App *)reviewApp country:(Country *)reviewCountry delegate:(NSObject <ReviewScraperDelegate> *) scrDelegate
{
	if (self = [super init])
	{
		self.app = reviewApp;
		self.country = reviewCountry;
		scraperDelegate = scrDelegate;
		
		workInProgress = YES;
		
	}
	
	return self;
}

- (void) dealloc
{
	[app release];
	[country release];
	[super dealloc];
}
	

- (void)main
{
	NSMutableArray *scrapedReviews = [NSMutableArray array];
	BOOL thereIsMore;
	
	NSUInteger pageNumber = 0;
	
	// main thread
	if (delegate && [delegate respondsToSelector:@selector(downloadStartedForOperation:)])
	{
		[delegate performSelectorOnMainThread:@selector(downloadStartedForOperation:) withObject:self waitUntilDone:NO];
	}
	
	do
	{
		thereIsMore = NO;
		
		NSString *urlString = [NSString stringWithFormat:@"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?sortOrdering=4&onlyLatestVersion=false&sortAscending=true&pageNumber=%d&type=Purple+Software&id=%d", pageNumber, app.apple_identifier];
		
		NSURL *url = [NSURL URLWithString:urlString];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
		[request addValue:[NSString stringWithFormat:@"%d-1,2", country.appStoreID] forHTTPHeaderField:@"X-Apple-Store-Front"];
		[request addValue:@"iTunes-iPhone/2.2 (2)" forHTTPHeaderField:@"User-Agent"];
		//[request addValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"]; // doesn't work.
		
		NSURLResponse* response; NSError* error;
		NSData* data = [NSURLConnection sendSynchronousRequest: request returningResponse:&response error:&error];
		
		if (!data) 
		{
			[self sendFinishToDelegate];
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
				
				if (![contentType isEqualToString:@"text/xml"])
				{
					NSLog(@"Got Content Type: %@", contentType);
					NSString *sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
					NSLog(@"%@", sourceSt);
					
					[self sendFinishToDelegate];
					return;
				}
			}
			else 
			{
				NSLog(@"Got status code %d", statusCode);

				[self sendFinishToDelegate];
				return;
			}
		}
				
		
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfData:data];
		
		
		NSArray *reviews = [dict objectForKey:@"items"];
		
		for (NSDictionary *oneReview in reviews)
		{
			NSString *rawTitle = [oneReview objectForKey:@"title"];
			NSScanner *titleScanner = [NSScanner scannerWithString:rawTitle];
			
			if ([[oneReview objectForKey:@"type"] isEqualToString:@"review"])
			{
				// skip leading no.
				[titleScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] intoString:NULL];
				
				NSRange versionPos = [rawTitle rangeOfString:@"(" options:NSBackwardsSearch];
				
				NSString *title = [[rawTitle substringWithRange:NSMakeRange([titleScanner scanLocation], versionPos.location-[titleScanner scanLocation])] 
								   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				[titleScanner setScanLocation:versionPos.location+2];  // skip (v
				
				NSString *version = nil;
				
				NSMutableCharacterSet *legalVersionChars = [NSMutableCharacterSet alphanumericCharacterSet];
				[legalVersionChars formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
				
				[titleScanner scanCharactersFromSet:legalVersionChars intoString:&version];
				
				NSString *review = [oneReview objectForKey:@"text"];
				NSString *userline = [oneReview objectForKey:@"user-name"];
				NSArray *parts = [userline componentsSeparatedByString:@" on "];
				
				NSString *user = [[parts objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				NSString *dateString = [parts objectAtIndex:1];
				
				
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				// May 4, 2009
				[dateFormatter setDateFormat:@"MMM dd, yyyy"]; /* Unicode Locale Data Markup Language */
				//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
				NSDate *reviewDate = [dateFormatter dateFromString:dateString]; 
				[dateFormatter release];
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"dd-MMM-yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"dd-MM-yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"dd.MMM.yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"dd.MM.yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"fr_FR"] autorelease];
					[dateFormatter setLocale:frLocale];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"dd MMM yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"es_ES"] autorelease];
					[dateFormatter setLocale:frLocale];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"dd-MMM-yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"it_IT"] autorelease];
					[dateFormatter setLocale:frLocale];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"dd-MMM-yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
					[dateFormatter setLocale:frLocale];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"dd-MMM-yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				
				if (!reviewDate)
				{
					dateFormatter = [[NSDateFormatter alloc] init];
					NSLocale *frLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
					[dateFormatter setLocale:frLocale];
					// 09-Oct-2008
					[dateFormatter setDateFormat:@"MMM dd, yyyy"]; /* Unicode Locale Data Markup Language */
					//[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
					reviewDate = [dateFormatter dateFromString:dateString]; 
					[dateFormatter release];
				}
				if (!reviewDate)
				{
					NSLog(@"Cannot parse date: '%@'", dateString);
				}
				if (!version)
				{
					NSLog(@"Cannot parse version: '%@'", version);
				}
				
				
				double stars = [[oneReview objectForKey:@"average-user-rating"] doubleValue];
				
				Review *newReview = [[Review alloc] initWithApp:app country:country title:title name:user version:version date:reviewDate review:review stars:stars];
				
				[scrapedReviews addObject:newReview];
				[newReview release];
			}
			else if ([[oneReview objectForKey:@"type"] isEqualToString:@"more"])
			{
				thereIsMore = YES;
				pageNumber++;
			}
			else 
			{
				//NSLog(@"%@", oneReview);
			}
			
			
		} 
		
	} while (thereIsMore);
	
	workInProgress = NO;
	
	if ([scrapedReviews count]&&scraperDelegate && [scraperDelegate respondsToSelector:@selector(didFinishRetrievingReviews:)])
	{
		// tell the delegate that we have scraped reviews, and do it on main thread to be safe
		[scraperDelegate performSelectorOnMainThread:@selector(didFinishRetrievingReviews:) withObject:[NSArray arrayWithArray:scrapedReviews] waitUntilDone:YES];
	}
	
	[self sendFinishToDelegate];	
}

- (BOOL) isFinished
{
	return !workInProgress;
}

- (BOOL) isConcurrent
{
	return NO;
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

@end
