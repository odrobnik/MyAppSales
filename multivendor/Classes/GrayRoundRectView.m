//
//  GrayRoundRectView.m
//  ELO
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "GrayRoundRectView.h"


@implementation GrayRoundRectView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.clearsContextBeforeDrawing = NO;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	 float ovalWidth = 20.0f, ovalHeight = 20.0f, fw, fh;
	 
	 CGContextSetLineWidth(context, 1.0);
	 CGContextBeginPath(context);
	 CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect)); // Translates the origin of the graphics context to the lower-left corner of the rectangle.
	 CGContextScaleCTM (context, ovalWidth, ovalHeight); // Normalizes the scale of the graphics context so that the width and height of the arcs are 1.0.
	 fw = CGRectGetWidth (rect) / ovalWidth; // Calculates the width of the rectangle in the new coordinate system.
	 fh = CGRectGetHeight (rect) / ovalHeight; // Calculates the height of the rectangle in the new coordinate system.
	 CGContextMoveToPoint(context, fw, fh/2); // Moves to the mid point of the right edge of the rectangle.
	 CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 0.5); // Adds an arc to the starting point. This is the upper-right corner of the rounded rectangle.
	 CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 0.5); // Adds an arc that defines the upper-left corner of the rounded rectangle.
	 CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 0.5); // Adds an arc that defines the lower-left corner of the rounded rectangle.
	 CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 0.5); // Adds an arc that defines the lower-right corner of the rounded rectangle.
	 CGContextClosePath(context); //Closes the path, which connects the current point to the starting point, and terminates the subpath.
	 
	 CGContextSetRGBFillColor(context, 0, 0, 0, 0.5);
	 CGContextFillPath(context);
}




- (void)dealloc {
    [super dealloc];
}


@end
