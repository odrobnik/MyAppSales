//
//  ReviewDownloaderOperation.m
//  ASiST
//
//  Created by Oliver on 13.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "ReviewDownloaderOperation.h"
#import "NSDictionary+Helpers.h"

#import "NSString+Helpers.h"
#import "NSString+Review.h"



@interface ReviewDownloaderOperation ()
- (void) sendFinishToDelegate;
@end;



@implementation ReviewDownloaderOperation

- (id) initForAppID:(NSInteger)appID storeID:(NSInteger)storeID delegate:(NSObject <ReviewScraperDelegate> *) scrDelegate;
{
	if ((self = [super init]))
	{
		_appID = appID;
		_storeID = storeID;
		
		scraperDelegate = scrDelegate;
		
		workInProgress = YES;
		
	}
	
	return self;
}

- (void) dealloc
{
	[iso2 release];
	[super dealloc];
}





- (void)parseData:(NSData *)data
{
	NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSScanner *scanner = [NSScanner scannerWithString:dataString];
	
	BOOL scanning = YES;
	BOOL foundReview = NO;
	
	while(scanning)
	{
		NSString *reviewTitle = nil;
		NSString *reviewRating = nil;
		NSString *reviewName = nil;
		NSString *reviewText = nil;
		NSString *reviewVersion = nil;
		
		[scanner scanUpToString:@"<TextView topInset=\"0\" truncation=\"right\" leftInset=\"0\" squishiness=\"1\" styleSet=\"basic13\" textJust=\"left\" maxLines=\"1\"><SetFontStyle normalStyle=\"textColor\"><b>" intoString:NULL];
		foundReview = [scanner scanString:@"<TextView topInset=\"0\" truncation=\"right\" leftInset=\"0\" squishiness=\"1\" styleSet=\"basic13\" textJust=\"left\" maxLines=\"1\"><SetFontStyle normalStyle=\"textColor\"><b>" intoString:NULL];
		[scanner scanUpToString:@"</b>" intoString:&reviewTitle];
		
		if(foundReview == NO)
		{
			break;
		}
		
		[scanner scanUpToString:@"<HBoxView topInset=\"1\" alt=\"" intoString:NULL];
		[scanner scanString:@"<HBoxView topInset=\"1\" alt=\"" intoString:NULL];
		[scanner scanUpToString:@" " intoString:&reviewRating];
		
		[scanner scanUpToString:@"<TextView topInset=\"0\" truncation=\"right\" leftInset=\"0\" squishiness=\"1\" styleSet=\"basic13\" textJust=\"left\" maxLines=\"1\"><SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
		[scanner scanString:@"<TextView topInset=\"0\" truncation=\"right\" leftInset=\"0\" squishiness=\"1\" styleSet=\"basic13\" textJust=\"left\" maxLines=\"1\"><SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
		[scanner scanUpToString:@"\">" intoString:NULL];
		[scanner scanString:@"\">" intoString:NULL];
		[scanner scanUpToString:@"</GotoURL>" intoString:&reviewName];
		reviewName = [reviewName stringByReplacingOccurrencesOfString:@"<b>" withString:@""];
		reviewName = [reviewName stringByReplacingOccurrencesOfString:@"</b>" withString:@""];
		reviewName = [reviewName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		[scanner scanString:@"</GotoURL>" intoString:NULL];
		[scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewVersion];
		
		NSArray *versionParts = [reviewVersion componentsSeparatedByString:@"- \n"];
		
		[scanner scanUpToString:@"<TextView topInset=\"2\" leftInset=\"0\" rightInset=\"0\" styleSet=\"normal11\" textJust=\"left\"><SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
		[scanner scanString:@"<TextView topInset=\"2\" leftInset=\"0\" rightInset=\"0\" styleSet=\"normal11\" textJust=\"left\"><SetFontStyle normalStyle=\"textColor\">" intoString:NULL];
		[scanner scanUpToString:@"</SetFontStyle>" intoString:&reviewText];
		
		if ([versionParts count]==3)
		{
			NSString *onlyVersion = [[[[versionParts objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "] lastObject];
			NSString *onlyDate = [[versionParts objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			NSDate *reviewDate = [onlyDate dateFromReviewDataString];
			double rating = [reviewRating doubleValue]/5.0;
			
			// hash
			NSString *combinedString = [NSString stringWithFormat:@"%@-%@-%d", onlyVersion, reviewName, _appID];
			
			NSString *hash = [combinedString md5];
			NSLog(@"c: %@ hash: %@", combinedString, hash);
			
			// put all into a dictionary
			NSDictionary *reviewDict = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInt:_appID], @"AppID",
										[NSNumber numberWithInt:_storeID], @"StoreID",
										[reviewTitle stringByUrlDecoding], @"ReviewTitle",
										reviewName, @"UserName",
										onlyVersion, @"Version",
										reviewDate, @"ReviewDate",
										[reviewText stringByUrlDecoding], @"ReviewText",
										[NSNumber numberWithDouble:rating], @"Rating", 
										hash, @"Hash", 
										iso2, @"ISO2", nil];
			
			NSLog(@"%@", reviewDict);
			[scrapedReviews addObject:reviewDict];
			
			/*			
			 Review_v1 *newReview = [[Review_v1 alloc] initWithApp:app country:country title:[reviewTitle stringByUrlDecoding]
			 name:reviewName version:onlyVersion 
			 date:reviewDate 
			 review:[reviewText stringByUrlDecoding] 
			 stars:stars];
			 [scrapedReviews addObject:newReview];
			 [newReview release];
			 */
		}
	}
}




- (void)main
{
	scrapedReviews = [NSMutableArray array];
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
		
		NSString *urlString = [NSString stringWithFormat:@"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?sortOrdering=4&onlyLatestVersion=false&sortAscending=true&pageNumber=%d&type=Purple+Software&id=%d", pageNumber, _appID];
		
		NSURL *url = [NSURL URLWithString:urlString];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
		[request addValue:[NSString stringWithFormat:@"%d-1", _storeID] forHTTPHeaderField:@"X-Apple-Store-Front"];
		//[request addValue:@"iTunes-iPhone/2.2 (2)" forHTTPHeaderField:@"User-Agent"];
		[request addValue:@"iTunes-iPhone/2.2 (2)" forHTTPHeaderField:@"User-Agent"];
		
		//[request addValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"]; // doesn't work.
		
		NSURLResponse* response; NSError* error;
		NSData* data = [NSURLConnection sendSynchronousRequest: request returningResponse:&response error:&error];
		
		if (!data) 
		{
			workInProgress = NO;
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
					
					workInProgress = NO;
					[self sendFinishToDelegate];
					return;
				}
			}
			else 
			{
				NSLog(@"Got status code %d for store %d", statusCode, _storeID);
				
				workInProgress = NO;
				[self sendFinishToDelegate];
				return;
			}
		}
		
		
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfData:data];
		
		
		if (!dict)
		{
			NSString *sourceSt = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding] autorelease];
			
			// itms format
			[self parseData:data];
			
			
			NSString *nextPageURL = [NSString stringWithFormat:@"<GotoURL target=\"main\" draggingURL=\"http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?pageNumber=%d", pageNumber+1];
			
			if ([sourceSt rangeOfString:nextPageURL].location!=NSNotFound)
			{
				thereIsMore = YES;
				pageNumber++;
			}
			
		}
		else
		{
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
					
					NSString *reviewTitle = [[rawTitle substringWithRange:NSMakeRange([titleScanner scanLocation], versionPos.location-[titleScanner scanLocation])] 
											 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					
					[titleScanner setScanLocation:versionPos.location+2];  // skip (v
					
					NSString *version = nil;
					
					NSMutableCharacterSet *legalVersionChars = [NSMutableCharacterSet alphanumericCharacterSet];
					[legalVersionChars formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
					
					[titleScanner scanCharactersFromSet:legalVersionChars intoString:&version];
					
					NSString *reviewText = [oneReview objectForKey:@"text"];
					NSString *userline = [oneReview objectForKey:@"user-name"];
					NSArray *parts = [userline componentsSeparatedByString:@" on "];
					
					NSString *reviewName = [[parts objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSString *dateString = [parts objectAtIndex:1];
					
					
					NSDate *reviewDate;
					
					reviewDate = [dateString dateFromReviewDataString];
					
					
					if (!version)
					{
						NSLog(@"Cannot parse version: '%@'", version);
					}
					
					
					double rating = [[oneReview objectForKey:@"average-user-rating"] doubleValue];
					
					// hash
					NSString *combinedString = [NSString stringWithFormat:@"%@-%@-%d", version, reviewName, _appID];
					NSString *hash = [combinedString md5];
					
					// put all into a dictionary
					NSDictionary *reviewDict = [NSDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithInt:_appID], @"AppID",
												[NSNumber numberWithInt:_storeID], @"StoreID",
												[reviewTitle stringByUrlDecoding], @"ReviewTitle",
												reviewName, @"UserName",
												version, @"Version",
												reviewDate, @"ReviewDate",
												reviewText, @"[reviewText stringByUrlDecoding]",
												[NSNumber numberWithDouble:rating], @"Rating", 
												hash, @"Hash", 
												iso2, @"ISO2", 
												nil];
					[scrapedReviews addObject:reviewDict];
					
					/*				
					 Review_v1 *newReview = [[Review_v1 alloc] initWithApp:app country:country title:title name:user version:version date:reviewDate review:review stars:stars];
					 
					 NSDictionary *reviewDict = [NSDictionary dictionaryWithObjectsAndKeys:app.apple_identifier, @"AppID",
					 country.iso3, @"CountryID",
					 title, @"title",
					 user, @"userName",
					 version, @"version",
					 reviewDate, @"date",
					 review, @"text",
					 [NSNumber numberWithDouble:stars/5.0], @"ratingPercent",
					 nil];
					 
					 [scrapedReviews addObject:newReview];
					 [newReview release];
					 */
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


@synthesize delegate;
@synthesize appID = _appID;
@synthesize storeID = _storeID;
@synthesize iso2;


@end
