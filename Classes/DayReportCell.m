//
//  DayReportCell.m
//  ASiST
//
//  Created by Oliver on 26.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "DayReportCell.h"
#import "CalendarDayView.h"

#define MAIN_FONT_SIZE 24.0

@implementation DayReportCell

@synthesize dayView;
@synthesize unitsSoldLabel, royaltyEarnedLabel, unitsUpdatedLabel;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = TABLEVIEWCELL_PLAIN_INIT))
    {
        // Initialization code
		
		dayView = [[CalendarDayView alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:dayView];

		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		unitsSoldLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		unitsSoldLabel.backgroundColor = [UIColor clearColor];
		//unitsSoldLabel.opaque = NO;
		//unitsSoldLabel.textColor = [UIColor blackColor];
		//unitsSoldLabel.highlightedTextColor = [UIColor whiteColor];
		unitsSoldLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		unitsSoldLabel.textAlignment = UITextAlignmentCenter;
		unitsSoldLabel.adjustsFontSizeToFitWidth = YES;
		unitsSoldLabel.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		[self.contentView addSubview:unitsSoldLabel];
		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		royaltyEarnedLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		royaltyEarnedLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		//royaltyEarnedLabel.backgroundColor = [UIColor clearColor];
		royaltyEarnedLabel.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		royaltyEarnedLabel.textAlignment = UITextAlignmentRight;
		[self.contentView addSubview:royaltyEarnedLabel];
		
		/*
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		unitsUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		unitsUpdatedLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		//unitsUpdatedLabel.backgroundColor = [UIColor clearColor];
		unitsUpdatedLabel.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		unitsUpdatedLabel.textAlignment = UITextAlignmentCenter;
		[self.contentView addSubview:unitsUpdatedLabel]; */
		
    }
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self bounds];
	
	dayView.frame = CGRectMake(0, 0, contentRect.size.height, contentRect.size.height);
	
	CGRect frame = CGRectMake(contentRect.size.height + 10.0, 0, (contentRect.size.width-contentRect.size.height - 40.0) /3.0, contentRect.size.height-1.0);
	unitsSoldLabel.frame = frame;
	frame.origin.x += frame.size.width;
	frame.size.width *= 2.0;
	royaltyEarnedLabel.frame = frame;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
	[unitsSoldLabel release];
	[royaltyEarnedLabel release];
	[unitsUpdatedLabel release];
	[dayView release];
    [super dealloc];
}


@end
