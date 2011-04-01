//
//  AppIconDownloadOperation.m
//  ASiST
//
//  Created by Oliver on 29.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "AppIconDownloadOperation.h"


@implementation AppIconDownloadOperation

- (id)initWithApplicationIdentifier:(NSInteger)appID
{
	if ((self = [super init]))
	{
		_appID = appID;
	}
	return self;
}

- (void)dealloc
{
	[_appName release];
	[super dealloc];
}

- (void)main
{
	NSString *urlString = [NSString stringWithFormat:@"http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%d&amp;mt=8", _appID];
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:60.0];
	
	// apple requires fake user agent for icon download
	[request addValue:@"iTunes/10.0.1" forHTTPHeaderField:@"User-Agent"];
	
	NSURLResponse *response = nil;
	NSError *error = nil;
	
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (!data)
	{
		NSLog(@"Cannot retrieve app icon for id %d, %@", _appID, [error localizedDescription]);
		return;
	}
	
	if (![[response MIMEType] isEqualToString:@"text/xml"])
	{
		NSLog(@"Cannot retrieve app icon for id %d, response was not XML", _appID);
		return;
	}
	
	if ([self isCancelled])
	{
		return;
	}
	
	NSString *html = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSRange range = [html rangeOfString:@"<iTunes>"];
	if (range.location!=NSNotFound)
	{
		NSRange endRange = [html rangeOfString:@"</iTunes>" options:NSLiteralSearch range:NSMakeRange(range.location+range.length, 1000)];
		
		NSRange tempRange = NSMakeRange(range.location + range.length, endRange.location - range.location - range.length);
		
		
		// record the online name
		self.appName = [[html substringWithRange:tempRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	}
	
	range = [html rangeOfString:@"100x100-75.jpg"];
	
	if (range.location==NSNotFound)
	{
		NSLog(@"No icon found in HTML");
		return;
	}
	
	
	
	NSRange httpRange = [html rangeOfString:@"http://" options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
	NSString *imgURL = [html substringWithRange:NSMakeRange(httpRange.location, range.location - httpRange.location + range.length)];
	
	// hack: get higher res icon
	imgURL = [imgURL stringByReplacingOccurrencesOfString:@"100x100" withString:@"512x512"];
	
	NSLog(@"Got Icon URL: %@", imgURL);
	
	// now download the icon
	
	url = [NSURL URLWithString:imgURL];
	data = [NSData dataWithContentsOfURL:url];
	
	UIImage *image = [UIImage imageWithData:data];
	
	if (!image)
	{
		NSLog(@"Invalid image data");
		return;
	}
	
	
	UIImage *maskedImage = [image imageByRoundingCornersWithCornerWidth:90 cornerHeight:90];
	UIImage *scaledImage = [maskedImage imageByScalingToSize:CGSizeMake(112, 112)];
	
	//UIImage *mask = [UIImage imageNamed:@"cover_mask_rounded_100x100.png"];
	//UIImage *maskedImage = [image imageByMaskingWithImage:mask];
	
	data = UIImagePNGRepresentation(scaledImage);
	
	
	// save it to caches folder
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *imageFileName = [NSString stringWithFormat:@"%d.png", self.appID];
	NSString *imagePath = [cachesPath stringByAppendingPathComponent:imageFileName];
	
	[data writeToFile:imagePath atomically:YES];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.appName, @"AppName", nil];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"AppIconLoaded" 
																	object:[NSNumber numberWithInt:_appID]
																  userInfo:userInfo];
}

@synthesize appID = _appID;
@synthesize appName = _appName;

@end
