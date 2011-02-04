//
//  UIImage+DTUtilities.h
//  ASiST
//
//  Created by Oliver on 11.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>




@interface UIImage (DTUtilities) 

- (UIImage *)imageByRoundingCornersWithCornerWidth:(int)cornerWidth cornerHeight:(int)cornerHeight;

- (UIImage *)imageByScalingToSize:(CGSize)size;


//+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
	
//- (UIImage*)scaleImageToSize:(CGSize)newSize;
	
- (UIImage*) imageByMaskingWithImage:(UIImage *)maskImage; 

@end
