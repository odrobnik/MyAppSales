//
//  UIImage+Helpers.m
//  ASiST
//
//  Created by Oliver on 11.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "UIImage+DTUtilities.h"


@implementation UIImage (DTUtilities)



CGContextRef newBitmapContextSuitableForSize(CGSize size)
{
	int pixelsWide = size.width;
	int pixelsHigh = size.height;
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
	// void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
	
    bitmapBytesPerRow   = (pixelsWide * 4); //4
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
	
	/* bitmapData = malloc( bitmapByteCount );
	 
	 memset(bitmapData, 0, bitmapByteCount);  // set memory to black, alpha 0
	 
	 if (bitmapData == NULL)
	 {
	 return NULL;
	 }
	 */
	colorSpace = CGColorSpaceCreateDeviceRGB();  	
	
	context = CGBitmapContextCreate ( NULL, // instead of bitmapData
									 pixelsWide,
									 pixelsHigh,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease( colorSpace );
	
    if (context== NULL)
    {
		// free (bitmapData);
        return NULL;
    }
	
    return context;
}

- (UIImage *)imageByRoundingCornersWithCornerWidth:(int)cornerWidth cornerHeight:(int)cornerHeight;
{
	UIImage * newImage = nil;
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int w = self.size.width;
	int h = self.size.height;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
	
	CGContextBeginPath(context);
	CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
	addRoundedRectToPath(context, rect, cornerWidth, cornerHeight);
	CGContextClosePath(context);
	CGContextClip(context);
	
	CGContextDrawImage(context, CGRectMake(0, 0, w, h), self.CGImage);
	
	CGImageRef imageMasked = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	
	newImage = [[UIImage imageWithCGImage:imageMasked] retain];
	CGImageRelease(imageMasked);
	
	[pool release];
	
    return [newImage autorelease];
}


- (UIImage *)imageByScalingToSize:(CGSize)size
{
	// begin a graphics context of sufficient size
	CGContextRef ctx = newBitmapContextSuitableForSize(size);
	
	// draw original image into the context
	CGRect imageRect = CGRectMake(0, 0, size.width, size.height);
	CGContextDrawImage(ctx, imageRect, self.CGImage);
	
	// make image out of bitmap context
	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	UIImage *retImage = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	
	// free the context
	CGContextRelease(ctx);
	
	return retImage;
}



- (UIImage*) imageByMaskingWithImage:(UIImage *)maskImage 
{
	CGImageRef maskRef = maskImage.CGImage; 
	
	CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
										CGImageGetHeight(maskRef),
										CGImageGetBitsPerComponent(maskRef),
										CGImageGetBitsPerPixel(maskRef),
										CGImageGetBytesPerRow(maskRef),
										CGImageGetDataProvider(maskRef), NULL, false);
	
	CGImageRef masked = CGImageCreateWithMask([self CGImage], mask);
	CGImageRelease(mask);
	UIImage *retImage = [UIImage imageWithCGImage:masked];
	CGImageRelease(masked);
	return retImage;
}


/*




+ (UIImage*)imageWithImage:(UIImage*)image 
			  scaledToSize:(CGSize)newSize;
{
	UIGraphicsBeginImageContext( newSize );
	[image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

- (UIImage*)scaleImageToSize:(CGSize)newSize
{
	return [UIImage imageWithImage:self scaledToSize:newSize];
}
 
*/ 
@end
