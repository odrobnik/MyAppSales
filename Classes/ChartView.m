//
//  ChartView.m
//  ASiST
//
//  Created by Oliver Drobnik on 20.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "ChartView.h"
//#import <QuartzCore/CoreAnimation.h>
#import "Database.h"



@implementation ChartView

@synthesize myData, max_chart_value, bottom_inset, column_width;

/*
+(Class)layerClass
{
	return [CATiledLayer class];
}
*/

- (id)initWithChartData:(NSDictionary *)dict
{
    if ((self = [super initWithFrame:CGRectZero]))
	{
        // Initialization code
		self.myData = dict;
		
		// default
		bottom_inset = 0.0;   // standard, but could be more if legend is larger // 20
		
		NSNumber *maxNum = [dict objectForKey:@"Maximum"];
		
		max_chart_value = [maxNum doubleValue];
		
		// x-Axis scaling
		switch ((ReportType)[[dict objectForKey:@"ReportType"] intValue]) {
			case ReportTypeDay:
			{
				column_width = 15.0;
				
				NSArray *rowLabels = [myData objectForKey:@"Rows"];

				double sizeWithThisWidth = column_width*([rowLabels count]-1);
				if (sizeWithThisWidth<320.0)
				{
					column_width = 320.0 / ([rowLabels count]-1);
					
				}
				break;
			}
			case ReportTypeWeek:
				column_width = 30.0;
				break;
			default:
				column_width = 10.0;
				break;
		}
		
		
		CGRect chartSize = [self chartDimensions];
		
		self.frame =chartSize;
		self.bounds = chartSize;
		// find max
    }
	
	//NSLog(@"End chart init");
    return self;
}

- (CGRect) chartDimensions
{
	NSArray *rowLabels = [myData objectForKey:@"Rows"];
	
	CGRect retRect = CGRectMake(0,0,column_width*([rowLabels count]-1), 367.0);

	
	// less than screen width -> change to screen width, that also affects charts with only one day
	if (retRect.size.width<320)
	{
		retRect.size.width=320.0;
	}
	
	if (retRect.size.width>2000.0)
	{
		retRect.size.width=2000.0;
	}
	return retRect;
}


- (NSDate *) dateFromString:(NSString *)rfc2822String
{
	if (!rfc2822String) return nil;
	
	if (!dateFormatterToRead)
	{
		dateFormatterToRead = [[NSDateFormatter alloc] init];
		[dateFormatterToRead setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"]; /* Unicode Locale Data Markup Language */
	}
	return [dateFormatterToRead dateFromString:rfc2822String]; /*e.g. @"Thu, 11 Sep 2008 12:34:12 +0200" */	
	
}

- (void)drawRect:(CGRect)rect 
{
	[self drawView:self inContext:UIGraphicsGetCurrentContext() bounds:self.bounds];
}


-(void)drawView:(ChartView *)view inContext:(CGContextRef)context bounds:(CGRect)bounds
{
    // Drawing code
	CGSize size = [self bounds].size;  // 320x460

	CGRect rect = bounds;
	
	// Draw the background
	CGContextSetGrayFillColor(context, 0.9, 1.0);
	 CGContextFillRect(context, rect);
	
	CGContextSetLineJoin(context, kCGLineJoinRound);
	
	double one_unit_x = column_width; 
	double one_unit_y = (size.height-20.0-bottom_inset)/max_chart_value;   // 20 to not touch top
	

	double pos_y; // = size.height;
	// if less then width move x so that chart is right aligned
	
	NSArray *rowLabels = [myData objectForKey:@"Rows"];
	
	double left_border_x =  rect.size.width - ([rowLabels count]-1)*(one_unit_x);
	double pos_x = left_border_x;
	
	
	
	// draw background, alternating weeks
	
	NSEnumerator *enu = [rowLabels objectEnumerator];
	NSDate *oneDate;
			
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateStyle:NSDateFormatterShortStyle];
	[format setTimeStyle:NSDateFormatterNoStyle];

	int last_week = 0;
	int last_week_length = 7;
	int week = 0;
	
	while ((oneDate = [self dateFromString:[enu nextObject]]))
	{
		NSDateComponents *weekdayComponents =
		[gregorian components:NSWeekCalendarUnit| NSWeekdayCalendarUnit fromDate:oneDate];
		week = [weekdayComponents week];
		
		CGRect backRect = CGRectMake(pos_x-(double)last_week_length*one_unit_x, 0, one_unit_x*(double)last_week_length, size.height);

		//int weekday = [weekdayComponents weekday];

		if (week!=last_week)
		{
			if (week%2)
			{
				CGContextSetGrayFillColor(context, 0.8, 1);
			}
			else
			{
				CGContextSetGrayFillColor(context, 0.85, 1);
			}
		
			CGContextFillRect(context, backRect);
		
			// draw a week number
			CGContextSetGrayFillColor(context, 0.1, 0.5);

			CGRect labelRect = CGRectInset(backRect, 3.0, 3.0);
			NSString *label;
			
			switch ((ReportType)[[myData objectForKey:@"ReportType"] intValue]) {
				case ReportTypeDay:
					label = [NSString stringWithFormat:@"Week %d", ((week-2)+52)%52+1];
					break;
				default:
					label = [NSString stringWithFormat:@"%d", ((week-2)+52)%52+1];
					break;
			}		
			
			CGSize labelSize = [label sizeWithFont:[UIFont systemFontOfSize:9.0]];
			if (labelSize.width<backRect.size.width)
			{
				[label drawInRect:labelRect withFont:[UIFont systemFontOfSize:9.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
			}
			last_week_length=1;
		}
		else
		{
			last_week_length++;
		}
		
		pos_x += one_unit_x;
		
		last_week = week;
	}
	

	// one more for rightmost week
	//{
		
		CGRect backRect = CGRectMake(pos_x-(double)last_week_length*one_unit_x, 0, one_unit_x*(double)last_week_length, size.height);

		week++;
		if (week%2)
		{
			CGContextSetGrayFillColor(context, 0.8, 1);
		}
		else
		{
			CGContextSetGrayFillColor(context, 0.85, 1);
		}
		
		CGContextFillRect(context, backRect);
		
		
		// draw a week number
		CGContextSetGrayFillColor(context, 0.1, 0.5);

		CGRect labelRect = CGRectInset(backRect, 3.0, 3.0);
		NSString *label;
		
		switch ((ReportType)[[myData objectForKey:@"ReportType"] intValue]) {
			case ReportTypeDay:
				label = [NSString stringWithFormat:@"Week %d", ((week-2)+52)%52+1];
				break;
			default:
				label = [NSString stringWithFormat:@"%d", ((week-2)+52)%52+1];
				break;
		}		
				
	
		CGSize labelSize = [label sizeWithFont:[UIFont systemFontOfSize:9.0]];
		if (labelSize.width<backRect.size.width)
		{
			if (labelRect.size.width>320.0)
			{
				labelRect.size.width = 320.0;
			}
			
			[label drawInRect:labelRect withFont:[UIFont systemFontOfSize:9.0] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
		}
		//last_week_length=1;
	//}
	
	
	// do it for all apps
	
	NSArray *colLabels = [myData objectForKey:@"Columns"];
	NSArray *data = [myData objectForKey:@"Data"];

	NSEnumerator *colEnu = [colLabels objectEnumerator];
	//NSString *col;

	int idx = 0;
	BOOL first_date = YES;

	// set a shadow for the lines
	CGSize myShadowOffset = CGSizeMake (2,  -2);// 2
	CGContextSetShadow (context, myShadowOffset, 2);
	
	
	
	// for all columns
	while ([colEnu nextObject]) 
	{
		NSEnumerator *rowEnu = [data objectEnumerator];
		NSArray *row;
	
		// reset drawing position to the left border
		pos_x = left_border_x;
		//pos_y = size.height - bottom_inset;

		first_date = YES;  // first point needs to move as well
		
		CGContextSetLineWidth(context, 2.0);
		[self setStrokeColorFromIndex:idx context:context];
		CGContextBeginPath(context);
		
		
		// for all rows in data
		while ((row = [rowEnu nextObject]))
		{
			NSNumber *value = [row objectAtIndex:idx];
			double s = [value doubleValue];
			pos_y = size.height - bottom_inset - s * one_unit_y;  // 20 for bottom inset, for legend
			
			if (first_date)
			{
				CGContextMoveToPoint(context, pos_x, pos_y);
			}
			
			CGContextAddLineToPoint(context, pos_x, pos_y);
			
			// next column
			pos_x += one_unit_x;
			first_date = NO;
		}
		
		// done drawing all points for this app
		CGContextStrokePath(context);
		idx++;
	}

	
	/*
	
			pos_x = rect.size.width - [sortedDictKeys count]*one_unit_x;
			pos_y = size.height-bottom_inset;
			CGContextSetLineWidth(context, 2.0);
			[self setStrokeColorFromIndex:idx context:context];
			CGContextBeginPath(context);
			
			CGContextMoveToPoint(context, pos_x, pos_y);
			
			NSEnumerator *enu = [self.sortedDictKeys objectEnumerator];
			NSDate *oneDate;
			
			pos_x = left_border_x;
			pos_y = size.height - bottom_inset;
			
			// reset enumerator for days
			enu = [self.sortedDictKeys objectEnumerator];
			
			first_date = YES;
			
			while ((oneDate = [enu nextObject]))
			{
				NSDictionary *appsDict = [dataRoot objectForKey:oneDate];
				double s=0;
				NSDictionary *oneApp = [appsDict objectForKey:appKey];
				if (oneApp)
				{
					NSNumber *sum = [oneApp objectForKey:@"Sum"];
					s = [sum doubleValue];
					
					pos_y = size.height - bottom_inset - s * one_unit_y;  // 20 for bottom inset, for legend
				}
				
				if (first_date)
				{
					CGContextMoveToPoint(context, pos_x, pos_y);
				}
				
				CGContextAddLineToPoint(context, pos_x, pos_y);
				
				
				
				// next column
				pos_x += one_unit_x;
				first_date = NO;
			}
			
			// done drawing all points for this app
			CGContextStrokePath(context);
			idx++;
			
			
		}
	}
	 */
	
	
	[format release];
	[gregorian release];
	
	
	
}

- (void)setStrokeColorFromIndex:(NSInteger)idx context:(CGContextRef)context
{
	switch (idx) {
		case 0:
			CGContextSetRGBStrokeColor(context, 1, 0, 0, 1.0);
			break;
		case 1:
			CGContextSetRGBStrokeColor(context, 0, 0.8, 0, 1.0);
			break;
		case 2:
			CGContextSetRGBStrokeColor(context, 0, 0, 1, 1.0);
			break;
		case 3:
			CGContextSetRGBStrokeColor(context, 1, 1, 0, 1.0);
			break;
		case 4:
			CGContextSetRGBStrokeColor(context, 0, 1, 1, 1.0);
			break;
		case 5:
			CGContextSetRGBStrokeColor(context, 1, 0, 1, 1.0);
			break;
		case 6:
			CGContextSetRGBStrokeColor(context, 1, 0.5, 0, 1.0);
			break;
		case 7:
			CGContextSetRGBStrokeColor(context, 0, 1, 0.5, 1.0);
			break;
		case 8:
			CGContextSetRGBStrokeColor(context, 0.5, 0, 1, 1.0);
			break;
		case 9:
			CGContextSetRGBStrokeColor(context, 0.5, 1, 0, 1.0);
			break;
		case 10:
			CGContextSetRGBStrokeColor(context, 0, 0.5, 1, 1.0);
			break;
		case 11:
			CGContextSetRGBStrokeColor(context, 0, 0, 0.5, 1.0);
			break;
			
		case 12:
			CGContextSetRGBStrokeColor(context, 1, 0.33, 0.33, 1.0);
			break;
		case 13:
			CGContextSetRGBStrokeColor(context, 0.33, 0.8, 0.33, 1.0);
			break;
		case 14:
			CGContextSetRGBStrokeColor(context, 0.33, 0.33, 1, 1.0);
			break;
		case 15:
			CGContextSetRGBStrokeColor(context, 1, 1, 0.33, 1.0);
			break;
		case 16:
			CGContextSetRGBStrokeColor(context, 0.33, 1, 1, 1.0);
			break;
		case 17:
			CGContextSetRGBStrokeColor(context, 1, 0.33, 1, 1.0);
			break;
		case 18:
			CGContextSetRGBStrokeColor(context, 1, 0.66, 0.33, 1.0);
			break;
		case 19:
			CGContextSetRGBStrokeColor(context, 0.33, 1, 0.66, 1.0);
			break;
		case 20:
			CGContextSetRGBStrokeColor(context, 0.66, 0.33, 1, 1.0);
			break;
		case 21:
			CGContextSetRGBStrokeColor(context, 0.66, 1, 0.33, 1.0);
			break;
		case 22:
			CGContextSetRGBStrokeColor(context, 0.33, 0.66, 1, 1.0);
			break;
		case 23:
			CGContextSetRGBStrokeColor(context, 0.33, 0.33, 0.66, 1.0);
			break;
			
		default:
			CGContextSetRGBStrokeColor(context, 0, 0,0, 1.0);
			break;
	}
	
	
	// more colors: jedes 0 -> 0.33 und jedes 0.5 zu 0.66, 1er bleiben gleich
	
}


- (void)dealloc {
	[dateFormatterToRead dealloc];
    [super dealloc];
}


@end
