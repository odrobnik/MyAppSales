//
//  Review+Custom.m
//  ASiST
//
//  Created by Oliver on 29.10.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "Review+Custom.h"
#import "Country.h"
#import "Product.h"

#import "NSString+Helpers.h"

@implementation Review (Custom)

- (NSString *)stringAsHTML
{
	NSMutableString *tmpString = [NSMutableString string];
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterMediumStyle];
	[df setTimeStyle:NSDateFormatterNoStyle];
	
	[tmpString appendFormat:@"<p><b>%@</b> (%.0f of 5)\n<br />", self.title, [self.ratingPercent doubleValue]*5.0];
	[tmpString appendFormat:@"by %@ (%@)\n<br />Version %@ - %@\n<br />", self.userName, self.country.name, self.appVersion, [df stringFromDate:self.date]];
	[tmpString appendFormat:@"<blockquote>%@</blockquote></p>", self.textTranslated?self.textTranslated:self.text];
	
	return [NSString stringWithString:tmpString];
}

+ (NSString *)hashFromVersion:(NSString *)version user:(NSString *)user appID:(id)appID
{
	if (!version || !user || !appID)
	{
		return nil;
	}
	
	NSString *combinedString = [NSString stringWithFormat:@"%@-%@-%@", version, user, appID];
	
	return [combinedString md5];
}


@end
