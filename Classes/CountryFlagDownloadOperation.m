//
//  CountryFlagDownloadOperation.m
//  ASiST
//
//  Created by Oliver on 28.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "CountryFlagDownloadOperation.h"


@implementation CountryFlagDownloadOperation

- (id)initWithISO3:(NSString *)iso3
{
	if (self = [super init])
	{
		self.iso3 = [iso3 lowercaseString];
	}
	
	return self;
}

- (void)dealloc
{
	[_iso3 release];
	[super dealloc];
}

- (void)main
{
	NSString *imageFileName = [NSString stringWithFormat:@"%@.png", self.iso3];
	NSURL *baseURL = [NSURL URLWithString:@"http://itunes.apple.com/images/flags/50/"];
	NSURL *url = [NSURL URLWithString:imageFileName relativeToURL:baseURL];
	
	NSURLRequest *request=[NSMutableURLRequest requestWithURL:url
												  cachePolicy:NSURLRequestUseProtocolCachePolicy
											  timeoutInterval:60.0];
	NSURLResponse *response = nil;
	NSError *error = nil;
	
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (!data)
	{
		NSLog(@"Cannot retrieve country flag for %@, %@", _iso3, [error localizedDescription]);
		return;
	}
	
	if (![[response MIMEType] isEqualToString:@"image/png"])
	{
		NSLog(@"Cannot retrieve country flag for %@, response was not a PNG", _iso3);
		return;
	}
	
	if ([self isCancelled])
	{
		return;
	}
	
	// save it to caches folder
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *imagePath = [cachesPath stringByAppendingPathComponent:imageFileName];
	
	[data writeToFile:imagePath atomically:YES];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"CountryFlagLoaded" object:self.iso3];
}

@synthesize iso3 = _iso3;

@end
