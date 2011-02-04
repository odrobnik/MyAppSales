//
//  LegendView.m
//  ASiST
//
//  Created by Oliver Drobnik on 22.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "LegendView.h"

#import "MyAppSalesAppDelegate.h"
#import "App.h"

@implementation LegendView

@synthesize required_height;

- (id)initWithFrame:(CGRect)frame Data:(NSDictionary *)data
{
	if (self = [super initWithFrame:frame]) {
        // Initialization code
		
		NSArray *colLabels = [data objectForKey:@"Columns"];
		
		// create enough labels for all apps

		NSEnumerator *enu = [colLabels objectEnumerator];
		NSString *oneApp;
		
		UIFont *theFont = [UIFont systemFontOfSize:8.0];
		double pos_x = frame.size.width - 3.0;
		double pos_y = frame.size.height-3.0;
		
		int idx = 0; 
		
		while (oneApp = [enu nextObject]) 
		{
				CGSize neededSize = [oneApp sizeWithFont:theFont];
				if (!required_height)
				{
					required_height = neededSize.height;
				}
				
				if ((pos_x- neededSize.width)<30.0)  // we would come into the axis view
				{
					pos_x = frame.size.width - 3.0;
					pos_y -= neededSize.height;
					required_height += neededSize.height;
				}
				
				CGRect neededRect = CGRectMake(pos_x-neededSize.width, pos_y-neededSize.height, neededSize.width, neededSize.height);
				
				pos_x -= (neededSize.width + 3.0);
				
				
				UILabel *tmpLabel = [[UILabel alloc]  initWithFrame:neededRect];
				tmpLabel.text = oneApp;
				[self setColorForLabel:tmpLabel fromIndex:idx];
				
				tmpLabel.shadowColor = [UIColor grayColor];
				
				tmpLabel.font = theFont;
				tmpLabel.backgroundColor = [UIColor clearColor];
				[self addSubview:tmpLabel];
				[tmpLabel release];
				
				idx++;
		}
		
		self.userInteractionEnabled = NO;
	}
    return self;
}


- (void)drawRect:(CGRect)rect 
{
	// Drawing code
//	CGContextRef context = UIGraphicsGetCurrentContext();
	
    // Drawing code
//	CGSize size = [self bounds].size;  // 320x460
	
	// Draw the background
//	CGContextSetGrayFillColor(context, 0.6, 0.5);
//	CGContextFillRect(context, rect);
	
	
	
	
	//CGRect labelRect = 
}

- (void)setColorForLabel:(UILabel *)aLabel fromIndex:(NSInteger)idx
{
	switch (idx) {
		case 0:
			[aLabel setTextColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
			break;
		case 1:
			[aLabel setTextColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:1]];
			break;
		case 2:
			[aLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:1]];
			break;
		case 3:
			[aLabel setTextColor:[UIColor colorWithRed:1 green:1 blue:0 alpha:1]];
			break;
		case 4:
			[aLabel setTextColor:[UIColor colorWithRed:0 green:1 blue:1 alpha:1]];
			break;
		case 5:
			[aLabel setTextColor:[UIColor colorWithRed:1 green:0 blue:1 alpha:1]];
			break;
		case 6:
			[aLabel setTextColor:[UIColor colorWithRed:1 green:0.5 blue:0 alpha:1]];
			break;
		case 7:
			[aLabel setTextColor:[UIColor colorWithRed:0 green:1 blue:0.5 alpha:1]];
			break;
		case 8:
			[aLabel setTextColor:[UIColor colorWithRed:0.5 green:0 blue:1 alpha:1]];
			break;
		case 9:
			[aLabel setTextColor:[UIColor colorWithRed:0.5 green:1 blue:0 alpha:1]];
			break;
		case 10:
			[aLabel setTextColor:[UIColor colorWithRed:0 green:0.5 blue:1 alpha:1]];
			break;
		case 11:
			[aLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0.5 alpha:1]];
			break;

 		case 12:
			[aLabel setTextColor:[UIColor colorWithRed:1 green:0.33 blue:0.33 alpha:1]];
			break;
		case 13:
			[aLabel setTextColor:[UIColor colorWithRed:0.33 green:1 blue:0.33 alpha:1]];
			break;
		case 14:
			[aLabel setTextColor:[UIColor colorWithRed:0.33 green:0.33 blue:1 alpha:1]];
			break;
		case 15:
			[aLabel setTextColor:[UIColor colorWithRed:1 green:1 blue:0.33 alpha:1]];
			break;
		case 16:
			[aLabel setTextColor:[UIColor colorWithRed:0.33 green:1 blue:1 alpha:1]];
			break;
		case 17:
			[aLabel setTextColor:[UIColor colorWithRed:1 green:0.33 blue:1 alpha:1]];
			break;
		case 18:
			[aLabel setTextColor:[UIColor colorWithRed:1 green:0.66 blue:0.33 alpha:1]];
			break;
		case 19:
			[aLabel setTextColor:[UIColor colorWithRed:0.33 green:1 blue:0.66 alpha:1]];
			break;
		case 20:
			[aLabel setTextColor:[UIColor colorWithRed:0.66 green:0.33 blue:1 alpha:1]];
			break;
		case 21:
			[aLabel setTextColor:[UIColor colorWithRed:0.66 green:1 blue:0.33 alpha:1]];
			break;
		case 22:
			[aLabel setTextColor:[UIColor colorWithRed:0.33 green:0.66 blue:1 alpha:1]];
			break;
		case 23:
			[aLabel setTextColor:[UIColor colorWithRed:0.33 green:0.33 blue:0.66 alpha:1]];
			break;
			
		default:
			[aLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
			break;
	}
}


- (void)dealloc {
    [super dealloc];
}


@end
