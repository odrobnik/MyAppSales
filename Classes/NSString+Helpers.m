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


- (NSString *) stringByUrlDecoding
{ 
	if ([self rangeOfString: @"&"].location == NSNotFound)
	{
		return self;
	}
	else
	{
		
		NSMutableString *escaped = [NSMutableString stringWithString: self];
		
		
		NSArray *entities = [NSArray arrayWithObjects: 
							 @"&amp;", @"&lt;", @"&gt;", @"&quot;",
							 /* 160 = nbsp */
							 @"&nbsp;", @"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
							 @"&sect;", @"&uml;", @"&copy;", @"&ordf;", @"&laquo;", @"&not;", @"&shy;", @"&reg;",
							 @"&macr;", @"&deg;", @"&plusmn;", @"&sup2;", @"&sup3;", @"&acute;", @"&micro;",
							 @"&para;", @"&middot;", @"&cedil;", @"&sup1;", @"&ordm;", @"&raquo;", @"&frac14;",
							 @"&frac12;", @"&frac34;", @"&iquest;", @"&Agrave;", @"&Aacute;", @"&Acirc;",
							 @"&Atilde;", @"&Auml;", @"&Aring;", @"&AElig;", @"&Ccedil;", @"&Egrave;",
							 @"&Eacute;", @"&Ecirc;", @"&Euml;", @"&Igrave;", @"&Iacute;", @"&Icirc;", @"&Iuml;",
							 @"&ETH;", @"&Ntilde;", @"&Ograve;", @"&Oacute;", @"&Ocirc;", @"&Otilde;", @"&Ouml;",
							 @"&times;", @"&Oslash;", @"&Ugrave;", @"&Uacute;", @"&Ucirc;", @"&Uuml;", @"&Yacute;",
							 @"&THORN;", @"&szlig;", @"&agrave;", @"&aacute;", @"&acirc;", @"&atilde;", @"&auml;",
							 @"&aring;", @"&aelig;", @"&ccedil;", @"&egrave;", @"&eacute;", @"&ecirc;", @"&euml;",
							 @"&igrave;", @"&iacute;", @"&icirc;", @"&iuml;", @"&eth;", @"&ntilde;", @"&ograve;",
							 @"&oacute;", @"&ocirc;", @"&otilde;", @"&ouml;", @"&divide;", @"&oslash;", @"&ugrave;",
							 @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;", nil];
		
		NSArray *characters = [NSArray arrayWithObjects:@"&", @"<", @">", @"\"", nil];
		
		int i, count = [entities count], characterCount = [characters count];
		
		// Html
		for(i = 0; i < count; i++)
		{
			NSRange range = [self rangeOfString: [entities objectAtIndex:i]];
			if(range.location != NSNotFound)
			{
				if (i < characterCount)
				{
					[escaped replaceOccurrencesOfString:[entities objectAtIndex: i] 
											 withString:[characters objectAtIndex:i] 
												options:NSLiteralSearch 
												  range:NSMakeRange(0, [escaped length])];
				}
				else
				{
					[escaped replaceOccurrencesOfString:[entities objectAtIndex: i] 
											 withString:[NSString stringWithFormat: @"%C", (160-characterCount) + i] 
												options:NSLiteralSearch 
												  range:NSMakeRange(0, [escaped length])];
				}
			}
		}
		
		// Decimal & Hex
		NSRange start, finish, searchRange = NSMakeRange(0, [escaped length]);
		i = 0;
		
		while(i < [escaped length])
		{
			start = [escaped rangeOfString: @"&#" 
								   options: NSCaseInsensitiveSearch 
									 range: searchRange];
			
			finish = [escaped rangeOfString: @";" 
									options: NSCaseInsensitiveSearch 
									  range: searchRange];
			
			if(start.location != NSNotFound && finish.location != NSNotFound &&
			   finish.location > start.location)
			{
				NSRange entityRange = NSMakeRange(start.location, (finish.location - start.location) + 1);
				NSString *entity = [escaped substringWithRange: entityRange];     
				NSString *value = [entity substringWithRange: NSMakeRange(2, [entity length] - 2)];
				
				[escaped deleteCharactersInRange: entityRange];
				
				if([value hasPrefix: @"x"])
				{
					unsigned tempInt = 0;
					NSScanner *scanner = [NSScanner scannerWithString: [value substringFromIndex: 1]];
					[scanner scanHexInt: &tempInt];
					[escaped insertString: [NSString stringWithFormat: @"%C", tempInt] atIndex: entityRange.location];
				}
				else
				{
					[escaped insertString: [NSString stringWithFormat: @"%C", [value intValue]] atIndex: entityRange.location];
				}
				i = start.location;
			}
			else i++;
			searchRange = NSMakeRange(i, [escaped length] - i);
		}
		
		return escaped; 
	}
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

