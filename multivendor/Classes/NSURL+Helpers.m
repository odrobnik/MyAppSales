//
//  NSURL+Helpers.m
//  ASiST
//
//  Created by Oliver on 14.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NSURL+Helpers.h"


@implementation NSURL (Helpers)



- (NSDictionary *) parameterDictionary
{
	NSString *paramName;
	NSString *paramValue;
	
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	NSScanner *scanner = [NSScanner scannerWithString:[self query]];
	
	while (![scanner isAtEnd])
	{
		[scanner scanUpToString:@"=" intoString:&paramName];
		[scanner scanString:@"=" intoString:nil];
		[scanner scanUpToString:@"&" intoString:&paramValue];
		[scanner scanString:@"&" intoString:nil];
		
		[tmpDict setObject:paramValue forKey:paramName];
	}
	
	return [NSDictionary dictionaryWithDictionary:tmpDict];
}

@end
