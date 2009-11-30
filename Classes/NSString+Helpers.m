//
//  NSString+Helpers.m
//  ASiST
//
//  Created by Oliver on 15.06.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NSString+Helpers.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSString (Helpers)

#pragma mark Helpers

- (NSDate *) dateFromString
{
	NSDate *retDate;
	
	switch ([self length]) 
	{
		case 8:
		{
			NSDateFormatter *dateFormatter8 = [[NSDateFormatter alloc] init];
			[dateFormatter8 setDateFormat:@"yyyyMMdd"]; /* Unicode Locale Data Markup Language */
			[dateFormatter8 setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
			retDate = [dateFormatter8 dateFromString:self]; 
			[dateFormatter8 release];
			return retDate;
		}
		case 10:
		{
			NSDateFormatter *dateFormatterToRead = [[NSDateFormatter alloc] init];
			[dateFormatterToRead setDateFormat:@"MM/dd/yyyy"]; /* Unicode Locale Data Markup Language */
			[dateFormatterToRead setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
			retDate = [dateFormatterToRead dateFromString:self];
			[dateFormatterToRead release];
			
			if (retDate)
			{
				return retDate;
			}
			else
			{
				// try another format
				
				NSDateFormatter *dateFormatterToRead = [[NSDateFormatter alloc] init];
				[dateFormatterToRead setDateFormat:@"yyyy-MM-dd"]; /* Unicode Locale Data Markup Language */
				[dateFormatterToRead setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
				retDate = [dateFormatterToRead dateFromString:self];
				[dateFormatterToRead release];
			}
			
			return retDate;

		}
	}
	
	return nil;
}

- (NSDate *) dateFromISO8601
{
	NSMutableString *str = [self mutableCopy];
    NSDateFormatter* sISO8601 = nil;
    
    if (!sISO8601) {
        sISO8601 = [[[NSDateFormatter alloc] init] autorelease];
        [sISO8601 setTimeStyle:NSDateFormatterFullStyle];
        [sISO8601 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    }
    if ([str hasSuffix:@"Z"]) 
	{
		[str deleteCharactersInRange:NSMakeRange(str.length-1, 1)];
		[sISO8601 setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    }    
    NSDate *d = [sISO8601 dateFromString:str];
	[str release];
    return d;
}

// pass in a HTML <select>, returns the options as NSArray 
- (NSArray *) optionsFromSelect
{
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
	NSString *tmpList = [[self stringByReplacingOccurrencesOfString:@">" withString:@"|"] stringByReplacingOccurrencesOfString:@"<" withString:@"|"];
	
	NSArray *listItems = [tmpList componentsSeparatedByString:@"|"];
	NSEnumerator *myEnum = [listItems objectEnumerator];
	NSString *aString;
	
	while (aString = [myEnum nextObject])
	{
		if ([aString rangeOfString:@"value"].location != NSNotFound)
		{
			NSArray *optionParts = [aString componentsSeparatedByString:@"="];
			NSString *tmpString = [[optionParts objectAtIndex:1] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
			[tmpArray addObject:tmpString];
		}
	}
	
	NSArray *retArray = [NSArray arrayWithArray:tmpArray];  // non-mutable, autoreleased
	[tmpArray release];
	return retArray;
}

- (NSArray *) arrayOfColumnNames
{
	NSArray *column_names = [self componentsSeparatedByString:@"\t"];	
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	
	for (NSString *oneName in column_names)
	{
		NSString *cleanName = [oneName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		[tmpArray addObject:cleanName];
	}
	
	if ([tmpArray count])
	{
		return [NSArray arrayWithArray:tmpArray];
	}
	else 
	{
		return nil;
	}

}

- (NSString *) getValueForNamedColumn:(NSString *)column_name headerNames:(NSArray *)header_names
{
	NSArray *columns = [self componentsSeparatedByString:@"\t"];
	NSInteger idx = [header_names indexOfObject:column_name];
	if (idx>=[columns count])
	{
		return nil;
	}
	
	return [[columns objectAtIndex:idx] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) stringByUrlEncoding
{
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,  (CFStringRef)self,  NULL,  (CFStringRef)@"!*'();:@&=+$,/?%#[]",  kCFStringEncodingUTF8) autorelease];
}

- (NSComparisonResult)compareDesc:(NSString *)aString
{
	return -[self compare:aString];
}


// method to calculate a standard md5 checksum of this string, check against: http://www.adamek.biz/md5-generator.php
- (NSString * )md5
{
	const char *cStr = [self UTF8String];
	unsigned char result [CC_MD5_DIGEST_LENGTH];
	CC_MD5( cStr, strlen(cStr), result );
	
	return [NSString 
			stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1],
			result[2], result[3],
			result[4], result[5],
			result[6], result[7],
			result[8], result[9],
			result[10], result[11],
			result[12], result[13],
			result[14], result[15]
			];
}

- (NSArray *)arrayWithHrefDicts
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	NSMutableArray *retArray = [NSMutableArray array];
	
	NSString *url;
	
	do 
	{
		url = nil;
		[scanner scanUpToString:@"<a href=\"" intoString:nil];
		
		if (![scanner isAtEnd])
		{
			[scanner setScanLocation:[scanner scanLocation]+9];
			// we found a href, get the content
		
			if ([scanner scanUpToString:@"\"" intoString:&url])
			{
				[scanner scanUpToString:@">" intoString:nil];
				[scanner setScanLocation:[scanner scanLocation]+1];
				
				NSString *contents;
				if ([scanner scanUpToString:@"</a>" intoString:&contents])
				{
					NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:url, 
											 @"url", 
											 [contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], @"contents", nil];
					
					[retArray addObject:tmpDict];
				}
				
			}
		}

	} while (url);
	
	return [NSArray arrayWithArray:retArray];
}


- (NSString *)hrefForLinkContainingText:(NSString *)searchText
{
	NSArray *linkDict = [self arrayWithHrefDicts];
	
	//NSLog(@"links: %@", linkDict);
	
	for (NSDictionary *oneDict in linkDict)
	{
		NSRange range = [[oneDict objectForKey:@"contents"] rangeOfString:searchText];
		
		if (range.length)
		{
			return [oneDict objectForKey:@"url"];
		}
	}
		
		
	return nil;	
}

- (NSString *)stringByFindingFormPostURLwithName:(NSString *)formName
{
	NSRange formRange;
	
	if (formName)
	{
		formRange = [self rangeOfString:[NSString stringWithFormat:@"method=\"post\" name=\"%@\" action=\"", formName]];

		if (formRange.location==NSNotFound)
		{
			formRange = [self rangeOfString:[NSString stringWithFormat:@"method=\"post\" name=\"%@\" enctype=\"multipart/form-data\" action=\"", formName]];
		}
	}
	else 
	{
		formRange = [self rangeOfString:@"method=\"post\" action=\""];
	}
	
	if (formRange.location!=NSNotFound)
	{
		NSRange quoteRange = [self rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(formRange.location+formRange.length, 100)];
		if (quoteRange.length)
		{
			return [self substringWithRange:NSMakeRange(formRange.location+formRange.length, quoteRange.location-formRange.location-formRange.length)];
			
		}
		else
		{
			// we found the form post, but not the ending quote, strange
			return nil;
		}

	}

	// not found a form post in here
	return nil;
}

// method to get the path for a file in the document directory
+ (NSString *) pathForFileInDocuments:(NSString *)fileName
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (NSString *) pathForLocalizedFileInAppBundle:(NSString *)fileName ofType:(NSString *)type
{
	// get localized path for file from app bundle
	NSBundle *thisBundle = [NSBundle mainBundle];
	return [thisBundle pathForResource:fileName ofType:type];
}

@end

