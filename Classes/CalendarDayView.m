//
//  CalendarDayView.m
//  ASiST
//
//  Created by Oliver on 25.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "CalendarDayView.h"

#define GRADIENT_ALPHA 0.5

@implementation CalendarDayView

@synthesize weekdayLabel, dayLabel, date;


static NSDateFormatter *dayFormat;
static NSCalendar *gregorian;




- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) 
	{
        // Initialization code
		//self.clearsContextBeforeDrawing = NO;
		//self.opaque = NO;
		
		
		weekdayLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		weekdayLabel.adjustsFontSizeToFitWidth = YES;
		weekdayLabel.opaque = NO;
		weekdayLabel.backgroundColor = [UIColor clearColor];
		weekdayLabel.textColor = [UIColor blackColor];
		weekdayLabel.textAlignment = UITextAlignmentCenter;
		weekdayLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		//weekdayLabel.shadowColor = [UIColor colorWithRed:147.0/255.0 green:21.0/255.0 blue:22.0/255.0 alpha:0.9];
		//weekdayLabel.shadowOffset = CGSizeMake(0, -1);
		[self addSubview:weekdayLabel];
		
		// weekdayLabel.text = @"Dienstag";
		
		
		dayLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self addSubview:dayLabel];
		
		// dayLabel.text = @"25";
		dayLabel.adjustsFontSizeToFitWidth = YES;
		dayLabel.opaque = NO;
		dayLabel.backgroundColor = [UIColor clearColor];
		dayLabel.textColor = [UIColor blackColor];
		dayLabel.textAlignment = UITextAlignmentCenter;
		dayLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		
		// init formatters
		if (!dayFormat)
		{
			dayFormat = [[NSDateFormatter alloc] init];
			[dayFormat setDateFormat:@"EEEE"];
		}
		
		if (!gregorian)
		{
			gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		}
		
		
		
		
		
    }
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self bounds];
	
	weekdayLabel.frame = CGRectMake(0, 0, contentRect.size.width, contentRect.size.height*0.31);
	dayLabel.frame = CGRectMake(0, contentRect.size.height*0.33, contentRect.size.width, contentRect.size.height*0.64);
	
	weekdayLabel.font = [UIFont systemFontOfSize:contentRect.size.height / 6.0];
	dayLabel.font = [UIFont boldSystemFontOfSize:contentRect.size.height / 1.5];
	
}



- (void)drawRect:(CGRect)rect 
{
	CGGradientRef myGradient;
	
	CGRect myRect = self.bounds;
	
	CGContextRef myContext = UIGraphicsGetCurrentContext();
	
	CGContextSetGrayFillColor(myContext, 1.0, 1.0);
	CGContextFillRect(myContext, myRect);
	/*
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
	 
	 CGContextSetRGBFillColor(context, 1, 0.5, 0.5, 1);
	 CGContextFillPath(context);
	 */
	
	CGPoint myStartPoint, myEndPoint;
	myStartPoint.x = 0.0;
	myStartPoint.y = 0.0;
	myEndPoint.x = 0.0;
	myEndPoint.y = myRect.size.height;
	
	// setup gradient
	
	
	size_t num_locations = 6;
	CGFloat locations[6] = { 0.0, 0.265, 0.28, 0.31, 0.36, 1.0 };
	CGFloat components[28] = { 239.0/256.0, 167.0/256.0, 170.0/256.0, GRADIENT_ALPHA,  // Start color
		207.0/255.0, 39.0/255.0, 39.0/255.0, GRADIENT_ALPHA,
		147.0/255.0, 21.0/255.0, 22.0/255.0, GRADIENT_ALPHA,
		175.0/255.0, 175.0/255.0, 175.0/255.0, GRADIENT_ALPHA,
		255.0/255.0,255.0/255.0, 255.0/255.0, GRADIENT_ALPHA,
		255.0/255.0,255.0/255.0, 255.0/255.0, GRADIENT_ALPHA
	}; // End color
	
	myGradient = CGGradientCreateWithColorComponents (CGColorSpaceCreateDeviceRGB(), components,
													  locations, num_locations);
	
	
	CGContextDrawLinearGradient (myContext, myGradient, myStartPoint, myEndPoint, 0);
	CGGradientRelease(myGradient);
	
	
	//CGContextBeginPath(myContext);
	CGContextSetGrayStrokeColor(myContext, 0.5, 0.5);
	CGContextMoveToPoint(myContext, myRect.size.width, 0);
	CGContextAddLineToPoint(myContext, myRect.size.width, myRect.size.height);
	CGContextStrokePath(myContext);
	
}

- (CGSize)sizeThatFits:(CGSize)size
{
	CGFloat smallerSize = MIN(size.width, size.height);
	
	return CGSizeMake(smallerSize, smallerSize);
}

- (void) setDate:(NSDate *)aDate
{
	if ((aDate == date))
	{
		return;
	}
	
	date = [aDate retain];
	
	weekdayLabel.text = [dayFormat stringFromDate:date];
	NSDateComponents *dayComps = [gregorian components:NSDayCalendarUnit|NSWeekdayCalendarUnit fromDate:date];
	
	int weekday = [dayComps weekday];
	
	if (weekday==1) // Sunday
	{   // 207.0/255.0, 39.0/255.0, 39.0/255.0
		dayLabel.textColor = [UIColor colorWithRed:0.52 green: 0.153 blue: 0.153 alpha:1.0];
	}
	else
	{
		dayLabel.textColor = [UIColor colorWithWhite:52.0/255.0 alpha:1.0];
	}
	
	dayLabel.text = [NSString stringWithFormat:@"%d", [dayComps day]];
}

- (void)dealloc {
	/* static:
	 CGGradientRelease(myGradient);
	 [gregorian release];
	 [dayFormat release]; */
	[date release];
	[dayLabel release];
	[weekdayLabel release];
    [super dealloc];
}


@end
