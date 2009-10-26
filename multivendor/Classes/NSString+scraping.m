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
	
	NSScanner *attributeScanner = [NSScanner scannerWithString:self];
	
	//NSMutableArray *attributeArray = [NSMutableArray array];
	
	while (![attributeScanner isAtEnd])
	{
		
		NSString *attrName;
		NSString *attrValue;
		
		
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&attrName];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
		[attributeScanner scanString:@"=" intoString:nil];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
		
		if ([attributeScanner scanString:@"\"" intoString:nil])
		{
			[attributeScanner scanUpToString:@"\"" intoString:&attrValue];	
			[attributeScanner scanString:@"\"" intoString:nil];
			
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
			
			NSString *inputAttributes;
			
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



@end
