//
//  UIImage+MyAppSales.m
//  ASiST
//
//  Created by Oliver on 30.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "UIImage+MyAppSales.h"
#import "UIImage+DTUtilities.h"

@implementation UIImage (MyAppSales)

+ (UIImage *)placeholderImageWithSize:(CGSize)size CornerRadius:(int)cornerRadius
{
	UIImage * newImage = nil;
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int w = size.width;
	int h = size.height;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
	
	CGContextBeginPath(context);
	CGRect rect = CGRectMake(0, 0, size.width, size.height);
	addRoundedRectToPath(context, rect, cornerRadius, cornerRadius);
	CGContextClosePath(context);
	CGContextClip(context);
		
	// will with gradient
	//133-166
	
	CGGradientRef glossGradient;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 166.0/255.0, 166.0/255.0, 166.0/255.0, 1.0,  // Start color
		133.0/255.0, 133.0/255.0, 133.0/255.0, 1.0 }; // End color
	
    glossGradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, num_locations);
	
    CGPoint topCenter = CGPointMake(CGRectGetMidX(rect), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGContextDrawLinearGradient(context, glossGradient, topCenter, midCenter, 0);
	
	rect = CGRectInset(rect, -1, 0);
	CGContextTranslateCTM(context, 0, 1);
	addRoundedRectToPath(context, rect, cornerRadius, cornerRadius);
	CGContextSetGrayStrokeColor(context, 202.0/255.0, 1);
	CGContextSetLineWidth(context, 2.0);
	CGContextStrokePath(context);
	
	
	CGImageRef imageMasked = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	
	newImage = [[UIImage imageWithCGImage:imageMasked] retain];
	CGImageRelease(imageMasked);
	
	[pool release];
	
    return [newImage autorelease];
}

@end
