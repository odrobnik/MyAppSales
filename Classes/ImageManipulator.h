//
//  ImageManipulator.h
//
//  Class for manipulating images.
//
//  Created by Björn Sållarp on 2008-09-11.
//  Copyright 2008 Björn Sållarp. All rights reserved.
//
//  Read my blog @ http://jsus.is-a-geek.org/blog
//

#import <UIKit/UIKit.h>


@interface ImageManipulator : NSObject {

}


+(UIImage *)makeRoundCornerImage:(UIImage*)img cornerWidth:(int) cornerWidth cornerHeight:(int) cornerHeight;

@end
