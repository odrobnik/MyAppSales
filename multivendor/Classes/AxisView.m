//
//  AxisView.m
//  ASiST
//
//  Created by Oliver Drobnik on 21.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "AxisView.h"


@implementation AxisView

@synthesize currency, bottom_inset, offset, scale;


- (id)initWithFrame:(CGRect)frame  max:(double)max_value currency:(NSString *)cur
{
    if (self = [super initWithFrame:frame]) 
	{
        // Initialization code
		max = max_value;
		self.currency = cur;
		self.bottom_inset = 0.0;   //standard, but could be more // 20
		self.userInteractionEnabled = NO;
		offset = CGPointZero;
		scale = 1.0;
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
	// Drawing code
	CGContextRef context = UIGraphicsGetCurrentContext();
	
    // Drawing code
	CGSize size = [self bounds].size;  // 320x460
	
	// Draw the background
	CGContextSetGrayFillColor(context,0.0, 0.1);
	CGContextFillRect(context, rect);
	
	double one_unit_y = (size.height*scale-bottom_inset-20.0*scale)/max;  // 20 to not touch top, 20 from bottom
	
	double step_size=0.01;
	
	while ((step_size*one_unit_y<20.0) && (step_size<1000))
	{
		if (step_size==0.01)
		{
			step_size=0.1;
		}
		else if (step_size==0.1)
		{
			step_size =1;
		}
		else
		{
			switch ((int)step_size) {
				case 1:
					step_size=5;
					break;
				case 5:
					step_size=10;
					break;
				case 10:
					step_size=25;
					break;
				case 25:
					step_size=50;
					break;
				case 50:
					step_size=100;
					break;
				case 100:
					step_size=250;
					break;
				case 250:
					step_size=500;
					break;
				default:
					step_size=1000;
					break;
			}
		}
		//		step_size = step_size*10.0;
	}
	
	
	double i;
	
	// for labels
	CGContextSetGrayFillColor(context, 0, 1);
	
	
	for (i=0;i<max;i+=step_size)
	{
		CGContextSetGrayStrokeColor(context, 0, 0.6);
		
		CGContextBeginPath(context);
		
		CGContextMoveToPoint(context, 0, size.height-bottom_inset+offset.y-i*one_unit_y); // 20.0 for bottom
		CGContextAddLineToPoint(context, size.width, size.height-bottom_inset+offset.y-i*one_unit_y);
		CGContextStrokePath(context);
		
		NSString *label;
		if (step_size<1.0)
		{
			label = [NSString stringWithFormat:@"%0.2f", i];
		}
		else
		{
			label = [NSString stringWithFormat:@"%0.f", i];
		}
		CGRect labelRect = CGRectMake(0, size.height-bottom_inset+offset.y-i*one_unit_y-12.0, size.width-5.0, 12.0);
		[label drawInRect:labelRect withFont:[UIFont systemFontOfSize:9.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
	}
	
	CGRect curRect = CGRectMake(0, size.height-bottom_inset+5.0, rect.size.width, 20.0);
	CGRectInset(curRect, 3, 3);
	[currency drawInRect:curRect withFont:[UIFont boldSystemFontOfSize:9.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
	
}


- (void)dealloc {
    [super dealloc];
}


@end
