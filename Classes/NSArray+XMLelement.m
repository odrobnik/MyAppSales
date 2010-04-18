//
//  NSArray+XMLelement.m
//  SOAP
//
//  Created by Oliver on 15.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NSArray+XMLelement.h"

#import "XMLelement.h"

@implementation NSArray (XMLelement)

- (XMLelement *)elementWhereAttribute:(NSString *)attribute HasValue:(NSString *)value
{
	for (XMLelement *oneElement in self)
	{
		if ([[oneElement.attributes objectForKey:attribute] isEqualToString:value])
		{
			return oneElement;
		}
	}	
		
	return nil;
}
//  

@end
