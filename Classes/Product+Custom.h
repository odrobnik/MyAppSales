//
//  Product+Custom.h
//  ASiST
//
//  Created by Oliver on 27.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "Product.h"

@interface Product (Custom)



- (UIImage *)iconImage;
- (NSString *)reviewsAsHTML;
- (void) getAllReviews;


@end
