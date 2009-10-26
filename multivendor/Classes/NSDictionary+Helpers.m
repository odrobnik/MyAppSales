//
//  NSDictionary+Helpers.m
//  ASiST
//
//  Created by Oliver on 13.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NSDictionary+Helpers.h"

@implementation NSDictionary (Helpers)

+ (NSDictionary *)dictionaryWithContentsOfData:(NSData *)data
{
	// uses toll-free bridging for data into CFDataRef and CFPropertyList into NSDictionary
	CFPropertyListRef plist =  CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (CFDataRef)data, 
															   kCFPropertyListImmutable, 
															   NULL);
	
	// we check if it is the correct type and only return it if it is
	if ([(id)plist isKindOfClass:[NSDictionary class]])
	{
		return [(NSDictionary *)plist autorelease];
	}
	else
	{
		// clean up ref
		CFRelease(plist);
		return nil;
	}
}

@end
