//
//  NSString+scraping.m
//  ASiST
//
//  Created by Oliver on 26.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NSString+scraping.h"


@implementation NSString (scraping)


- (NSDictionary *)dictionaryOfAttributesFromTag
{
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	NSString *stringToScan = self;
	
	NSScanner *attributeScanner = [NSScanner scannerWithString:stringToScan];
	
	//NSMutableArray *attributeArray = [NSMutableArray array];
	
	// skip leading <tagname

	NSString *temp = nil;

	if ([attributeScanner scanString:@"<" intoString:&temp])
	{
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&temp];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
	}
	
	while (![attributeScanner isAtEnd])
	{
		
		NSString *attrName = nil;
		NSString *attrValue = nil;
		
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&attrName];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
		[attributeScanner scanString:@"=" intoString:nil];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
		
		NSString *quote = nil;
		
		if ([attributeScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""] intoString:&quote])
		{
			[attributeScanner scanUpToString:quote intoString:&attrValue];	
			[attributeScanner scanString:quote intoString:&temp];
			
			[tmpDict setObject:attrValue forKey:attrName];
		}
		else
		{
			// no attribute found, scan to the end
			[attributeScanner setScanLocation:[self length]];
		}
	}
	
	if ([tmpDict count])
	{
		return [NSDictionary dictionaryWithDictionary:tmpDict];
	}
	else 
	{
		return nil;
	}
}



- (NSArray *)arrayOfInputs
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	NSScanner *inputScanner = [NSScanner scannerWithString:self];
	
	while (![inputScanner isAtEnd]) 
	{
		[inputScanner scanUpToString:@"<input " intoString:nil];
		if ([inputScanner scanString:@"<input " intoString:nil])
		{
			
			NSString *inputAttributes;
			
			
			
			[inputScanner scanUpToString:@">" intoString:&inputAttributes];
			
			[tmpArray addObject:[inputAttributes dictionaryOfAttributesFromTag]];
		}
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



- (NSArray *)arrayOfInputsForForm:(NSString *)formName
{
	NSScanner *inputScanner = [NSScanner scannerWithString:self];
	
	while (![inputScanner isAtEnd]) 
	{
		[inputScanner scanUpToString:@"<form " intoString:nil];
		if ([inputScanner scanString:@"<form " intoString:nil])
		{
			
			NSString *inputAttributes = nil;
			
			[inputScanner scanUpToString:@"</form>" intoString:&inputAttributes];
			
			NSDictionary *formAttributes = [inputAttributes dictionaryOfAttributesFromTag];
			
			if ([[formAttributes objectForKey:@"name"] isEqualToString:formName])
			{
				return [inputAttributes arrayOfInputs];
			}
		}
	}
	return nil;
}

- (NSDictionary *)dictionaryForInputInForm:(NSString *)formName withID:(NSString *)identifier
{
	NSArray *inputs = [self arrayOfInputsForForm:formName];
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@", identifier];
	
	NSArray *filteredInputs = [inputs filteredArrayUsingPredicate:pred];
	
	if ([filteredInputs count]!=1)
	{
		return nil;
	}
	
	return [filteredInputs lastObject];
}


- (NSString *)tagHTMLforTag:(NSString *)tag WithName:(NSString *)name
{
	NSScanner *inputScanner = [NSScanner scannerWithString:self];
	
	NSString *beginTag = [NSString stringWithFormat:@"<%@ ", tag];
	NSString *endTag = [NSString stringWithFormat:@"</%@>", tag];
	
	
	while (![inputScanner isAtEnd]) 
	{
		[inputScanner scanUpToString:beginTag intoString:nil];
		if ([inputScanner scanString:beginTag intoString:nil])
		{
			
			NSString *inputAttributes;
			
			[inputScanner scanUpToString:endTag intoString:&inputAttributes];
			
			NSDictionary *formAttributes = [inputAttributes dictionaryOfAttributesFromTag];
			
			if ([[formAttributes objectForKey:@"name"] isEqualToString:name])
			{
				return [NSString stringWithFormat:@"%@%@%@", beginTag, inputAttributes, endTag];
			}
		}
	}
	return nil;
}

- (NSString *)tagHTMLforTag:(NSString *)tag WithID:(NSString *)identifier
{
	NSScanner *inputScanner = [NSScanner scannerWithString:self];
	
	NSString *beginTag = [NSString stringWithFormat:@"<%@ ", tag];
	NSString *endTag = [NSString stringWithFormat:@"</%@>", tag];
	
	
	while (![inputScanner isAtEnd]) 
	{
		[inputScanner scanUpToString:beginTag intoString:nil];
		if ([inputScanner scanString:beginTag intoString:nil])
		{
			
			NSString *inputAttributes;
			
			[inputScanner scanUpToString:endTag intoString:&inputAttributes];
			
			NSDictionary *formAttributes = [inputAttributes dictionaryOfAttributesFromTag];
			
			for (NSString *oneAttributeKey in [formAttributes allKeys])
			{
				if ([[oneAttributeKey lowercaseString] isEqualToString:@"id"])
				{
					if ([[formAttributes objectForKey:oneAttributeKey] isEqualToString:identifier])
					{
						return [NSString stringWithFormat:@"%@%@%@", beginTag, inputAttributes, endTag];
					}
				}
			}
		}
	}
	return nil;
}

- (NSArray *)arrayOfHTMLForTags:(NSString *)tag matchingPredicate:(NSPredicate *)predicate
{
	NSScanner *inputScanner = [NSScanner scannerWithString:self];
	
	NSString *beginTag = [NSString stringWithFormat:@"<%@ ", tag];
	NSString *endTag = [NSString stringWithFormat:@"</%@>", tag];
	
	NSMutableArray *mutableArray = [NSMutableArray array];
	
	while (![inputScanner isAtEnd]) 
	{
		[inputScanner scanUpToString:beginTag intoString:nil];
		if ([inputScanner scanString:beginTag intoString:nil])
		{
			
			NSString *inputAttributes;
			
			[inputScanner scanUpToString:endTag intoString:&inputAttributes];
			
			NSDictionary *formAttributes = [inputAttributes dictionaryOfAttributesFromTag];
			
			if (!predicate || [predicate evaluateWithObject:formAttributes])
			{
				NSString *outerHTML = [NSString stringWithFormat:@"%@%@%@", beginTag, inputAttributes, endTag];
				
				[mutableArray addObject:outerHTML];
			}
		}
	}

	if (![mutableArray count])
	{
		return nil;
	}
	
	return [NSArray arrayWithArray:mutableArray];
}



- (NSString *)nameForTag:(NSString *)tag WithID:(NSString *)identifier
{
	NSString *html = [self tagHTMLforTag:tag WithID:identifier];
	NSDictionary *attributes = [html dictionaryOfAttributesFromTag];
	
	return [attributes objectForKey:@"name"];
}

- (NSDictionary *)dictionaryOfAttributesForTag:(NSString *)tag WithID:(NSString *)identifier
{
	// get html of this tag
	NSString *html = [self tagHTMLforTag:tag WithID:identifier];
	
	return [html dictionaryOfAttributesFromTag];
}

- (NSDictionary *)dictionaryOfAttributesForTag:(NSString *)tag WithName:(NSString *)name
{
	// get html of this tag
	NSString *html = [self tagHTMLforTag:tag WithName:name];
	
	return [html dictionaryOfAttributesFromTag];
}

- (NSString *)innerText
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[scanner scanString:@"<" intoString:NULL];
	
	NSString *tagName = nil;
	
	[scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&tagName];
	
	if (![tagName length])
	{
		return nil;
	}
	
	[scanner scanUpToString:@">" intoString:NULL];
	[scanner scanString:@">" intoString:NULL];
	
	NSString *innerString = nil;
	
	[scanner scanUpToString:@"<" intoString:&innerString];
	
	return innerString;
}


- (NSArray *)arrayOfTags:(NSString *)tag
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	NSScanner *inputScanner = [NSScanner scannerWithString:self];
	
	NSString *begin = [NSString stringWithFormat:@"<%@ ", tag];
	
	while (![inputScanner isAtEnd]) 
	{
		
		
		[inputScanner scanUpToString:begin intoString:NULL];
		if ([inputScanner scanString:begin intoString:NULL])
		{
			
			NSString *inputAttributes;
			
			
			
			[inputScanner scanUpToString:@">" intoString:&inputAttributes];
			
			[tmpArray addObject:[inputAttributes dictionaryOfAttributesFromTag]];
		}
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


- (NSArray *)arrayOfTags:(NSString *)tag matchingPredicate:(NSPredicate *)predicate
{
	NSArray *tags = [self arrayOfTags:tag];
	
	NSLog(@"%@", tags);
	
	if (predicate)
	{
		return [tags filteredArrayUsingPredicate:predicate];
	}
	else 
	{
		return tags;
	}
}


@end

#define MULTIPART_BOUNDARY @"----WebKitFormBoundaryo4y3bJWBcfhN2pyb"

@implementation NSString (FormPosting)

+ (NSString *)multipartBoundaryString
{
	return MULTIPART_BOUNDARY;
}

- (NSComparisonResult)compareAsWebObjectsIdentifier:(NSString *)otherString
{
	NSArray *selfComponents = [self componentsSeparatedByString:@"."];
	NSArray *otherComponents = [otherString componentsSeparatedByString:@"."];
	
	NSEnumerator *selfEnum = [selfComponents objectEnumerator];
	NSEnumerator *otherEnum = [otherComponents objectEnumerator];
	
	NSString *currentSelfObj;
	NSString *currentOtherObj;
	
	while (currentSelfObj = [selfEnum nextObject])
	{
		currentOtherObj = [otherEnum nextObject];
		
		int selfComp = [currentSelfObj intValue];
		int otherComp = [currentOtherObj intValue];

		if (selfComp<otherComp)
		{
			return NSOrderedAscending;
		}
		else if (selfComp>otherComp)
		{
			return NSOrderedDescending;
		}
	}
	
	return NSOrderedSame;
}
	
+ (NSString *)bodyForFormPostWithType:(FormPostType)type valueDictionaries:(NSArray *)valueDictionaries
{
	NSMutableString *bodyString = [NSMutableString string];

	NSString *boundary = [NSString multipartBoundaryString];
	
	if (type == FormPostTypeMultipart)
	{
		NSString *divider = [NSString stringWithFormat:@"--%@\r\n", boundary];

		for (NSDictionary *oneValueDict in valueDictionaries)
		{
			NSString *key = [[oneValueDict allKeys] lastObject];
			NSString *value = [oneValueDict objectForKey:key];
			
			[bodyString appendString:divider];
			[bodyString appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", key, value];
		}
		
		[bodyString appendFormat:@"--%@--\r\n", boundary];
	}
	
	return bodyString;
}
	
	
	

@end
