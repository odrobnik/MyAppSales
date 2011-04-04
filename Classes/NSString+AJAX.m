//
//  NSString+AJAX.m
//  ajax
//
//  Created by Oliver on 13.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "NSString+AJAX.h"
#import "NSString+Helpers.h"
#import "NSScanner+HTML.h"


@implementation NSString (AJAX)

// example: setUpdefaultVendorNavigation(){A4J.AJAX.Submit('j_id_jsp_618427933_0','defaultVendorPage',null,{'parameters':{'defaultVendorPage:j_id_jsp_618427933_2':'defaultVendorPage:j_id_jsp_618427933_2'} ,'actionUrl':'http://www.drobnik.com/vendor_default.faces';} )};

- (NSDictionary *)parametersFromAjaxStringCharactersScanned:(NSUInteger *)charactersScanned
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	
	NSString *leftValue = nil;
	NSString *rightValue = nil;
	
	NSCharacterSet *delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@",:{};"];

	while (![scanner isAtEnd]) 
	{
		NSInteger beginLoopPos = [scanner scanLocation];
		
		NSString *nextStr = nil;
		
		NSString *stringDelim = nil;
		
		if ([scanner scanString:@"'" intoString:&stringDelim])
		{
			if (leftValue)
			{
				[scanner scanUpToString:stringDelim intoString:&rightValue];
				
				[tmpDict setObject:rightValue forKey:leftValue];
				
				leftValue = rightValue = nil;
			}
			else 
			{
				[scanner scanUpToString:stringDelim intoString:&leftValue];
			}
			
			[scanner scanString:stringDelim intoString:NULL];
		} 
		else if ([scanner scanCharactersFromSet:delimiterSet intoString:&nextStr])
		{
			if ([nextStr isEqualToString:@"{"])
			{
				NSString *stringFromhere = [self substringFromIndex:[scanner scanLocation]];
				
				NSUInteger subChars = 0;
				NSDictionary *subParams = [stringFromhere parametersFromAjaxStringCharactersScanned:&subChars];
				
				if (subParams)
				{
					[tmpDict setObject:subParams forKey:leftValue];
					leftValue = nil;
				}
				
				[scanner setScanLocation:[scanner scanLocation] + subChars];
			}
			else if ([nextStr isEqualToString:@"}"])
			{
				if (charactersScanned)
				{
					*charactersScanned = [scanner scanLocation];
				}
				
				break;
			}
		}
        else 
        {
            if (leftValue)
			{
				[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",:;"] intoString:&rightValue];
                
                if ([rightValue hasPrefix:@"function"])
                {
                    [scanner setScanLocation:scanner.scanLocation - [rightValue length]];
                    
                    // scan entire function
                    [scanner scanFunctionString:&rightValue];
                }
				
				[tmpDict setObject:rightValue forKey:leftValue];
				
				leftValue = rightValue = nil;
			}
			else 
			{
				[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",:;"] intoString:&leftValue];
			}
         }
        
		// skip ,
		//[scanner scanString:@"," intoString:NULL];
		
		NSString *afterDelimiter = nil;
		[scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",:;"] intoString:&afterDelimiter];
		
		if ([scanner scanLocation]==beginLoopPos)
		{
			break;
		}
	}
	
	// prevent endless loop
	if (![tmpDict count])
	{
		return nil;
	}
	
	if (charactersScanned)
	{
		*charactersScanned = [scanner scanLocation];
	}
	
	return [NSDictionary dictionaryWithDictionary:tmpDict];
}

- (NSArray *)parametersFromAjaxSubmitStringForFunction:(NSString *)functionName
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	while (![scanner isAtEnd]) 
	{
		[scanner scanUpToString:@"function" intoString:NULL];

		if ([scanner scanString:@"function" intoString:NULL])
		{
			NSString *thisFunctionName = nil;
			
			if ([scanner scanUpToString:@"(" intoString:&thisFunctionName])
			{
				if ([scanner scanString:@"()" intoString:NULL])
				{
					NSString *functionBody = nil;
				
					[scanner scanUpToString:@")};" intoString:&functionBody];
					
					if ([functionName isEqualToString:thisFunctionName])
					{
						return [functionBody parametersFromAjaxSubmitString];
					}
				}
				
			}
		}
	}
	
	return nil;
}


- (NSArray *)parametersFromAjaxSubmitString
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	[scanner scanUpToString:@"A4J.AJAX.Submit" intoString:NULL];
	
	
	if ([scanner scanString:@"A4J.AJAX.Submit" intoString:NULL])
	{
		// found a submit
		[scanner scanUpToString:@"(" intoString:NULL];
		[scanner scanString:@"(" intoString:NULL];
		
		NSString *parameter = nil;
		
		NSCharacterSet *delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@",:{};"];
		
		while (![scanner isAtEnd]) 
		{
			NSString *nextStr = nil;
			
			NSString *stringDelim = nil;
			
			if ([scanner scanString:@"'" intoString:&stringDelim])
			{
				[scanner scanUpToString:stringDelim intoString:&parameter];
				
				[tmpArray addObject:parameter];
				
				[scanner scanString:stringDelim intoString:NULL];
			} 
			else if ([scanner scanCharactersFromSet:delimiterSet intoString:&nextStr])
			{
				if ([nextStr isEqualToString:@"{"])
				{
					NSString *stringFromhere = [self substringFromIndex:[scanner scanLocation]];
					
					NSUInteger subChars = 0;
					NSDictionary *subParams = [stringFromhere parametersFromAjaxStringCharactersScanned:&subChars];
					
					if (subParams)
					{
						[tmpArray addObject:subParams];
					}
					
					[scanner setScanLocation:[scanner scanLocation] + subChars];
				}
				else if ([nextStr isEqualToString:@"}"])
				{
					
					break;
				}
			}
			else 
			{
				// bare word
				if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",:;"] intoString:&parameter])
				{
					if ([parameter isEqualToString:@"null"])
					{
						[tmpArray addObject:[NSNull null]];
					}
				}
				
			}

			
			// skip ,
			//[scanner scanString:@"," intoString:NULL];
			
			NSString *afterDelimiter = nil;
			[scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",:;"] intoString:&afterDelimiter];
			
			// prevent endless loop
			if ([scanner scanLocation]==0)
			{
				break;
			}
		}
	}
	
	if (![tmpArray count])
	{
		return nil;
	}
	
	return [NSArray arrayWithArray:tmpArray];
}
		
		
- (NSString *)ajaxViewState
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	[scanner scanUpToString:@"javax.faces.ViewState" intoString:NULL];
	
	if ([scanner scanString:@"javax.faces.ViewState" intoString:NULL])
	{
		// skip forward to value
		[scanner scanUpToString:@"value" intoString:NULL];
		
		if ([scanner scanString:@"value" intoString:NULL])
		{
			if ([scanner scanString:@"=" intoString:NULL])
			{
				NSString *stringDelim = nil;
				
				if ([scanner scanString:@"\"" intoString:&stringDelim])
				{
					NSString *viewState = nil;
					
					if ([scanner scanUpToString:stringDelim intoString:&viewState])
					{
						return viewState;
					}
					
					return nil;
				}
				
			}
		}
	}
	
	return nil;
}

#pragma mark AJAX Request Building

+ (NSString *)ajaxRequestBodyWithParameters:(NSArray *)parameters viewState:(NSString *)viewState
{
	NSMutableString *tmpString = [NSMutableString string];
	
	[tmpString appendFormat:@"AJAXREQUEST=%@&", [[parameters objectAtIndex:0] stringByUrlEncoding]];
	[tmpString appendFormat:@"%@=%@&", [parameters objectAtIndex:1], [parameters objectAtIndex:1]];
	[tmpString appendFormat:@"javax.faces.ViewState=%@", [viewState stringByReplacingOccurrencesOfString:@":" withString:@"%3A"]];
	
	// find the dictionary
	NSDictionary *ajaxParameterDict = nil;
	
	for (id obj in parameters)
	{
		if ([obj isKindOfClass:[NSDictionary class]])
		{
			ajaxParameterDict = obj;
			break;
		}
	}
	
	NSDictionary *parameterDict = [ajaxParameterDict objectForKey:@"parameters"];
	
	for (NSString *key in [parameterDict allKeys])
	{
		[tmpString appendFormat:@"&%@=%@", [key stringByUrlEncoding],
		 [[parameterDict objectForKey:key] stringByUrlEncoding]];
	}
	
	[tmpString appendString:@"&"];
	
	return [NSString stringWithString:tmpString];
}


+ (NSString *)ajaxRequestBodyWithParameters:(NSArray *)parameters extraFormString:(NSString *)extraFormString viewState:(NSString *)viewState
{
	NSMutableString *tmpString = [NSMutableString string];
	
	[tmpString appendFormat:@"AJAXREQUEST=%@&", [[parameters objectAtIndex:0] stringByUrlEncoding]];
	[tmpString appendFormat:@"%@=%@&", [parameters objectAtIndex:1], [parameters objectAtIndex:1]];
	
	if (extraFormString)
	{
		[tmpString appendString:extraFormString];
		[tmpString appendString:@"&"];
	}
	
	[tmpString appendFormat:@"javax.faces.ViewState=%@", [viewState stringByReplacingOccurrencesOfString:@":" withString:@"%3A"]];
	
	// find the dictionary
	NSDictionary *ajaxParameterDict = nil;
	
	for (id obj in parameters)
	{
		if ([obj isKindOfClass:[NSDictionary class]])
		{
			ajaxParameterDict = obj;
			break;
		}
	}
	
	
	NSDictionary *parameterDict = [ajaxParameterDict objectForKey:@"parameters"];
	
	for (NSString *key in [parameterDict allKeys])
	{
		[tmpString appendFormat:@"&%@=%@", [key stringByUrlEncoding],
		 [[parameterDict objectForKey:key] stringByUrlEncoding]];
	}
	
	[tmpString appendString:@"&"];
	
	return [NSString stringWithString:tmpString];
}

		
@end
