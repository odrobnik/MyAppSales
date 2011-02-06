//
//  PeriodDayCell.h
//  iWoman
//
//  Created by Oliver Drobnik on 18.09.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReportCell.h"

@implementation ReportCell

@synthesize unitsSoldLabel, royaltyEarnedLabel, unitsUpdatedLabel, unitsRefundedLabel, countryCodeLabel;

#define LEFT_COLUMN_OFFSET 45.0
#define MAIN_FONT_SIZE 15.0

- (id)initWithFrame:(CGRect)frame reuseIdentifier:reuseIdentifier
{
	self = TABLEVIEWCELL_PLAIN_INIT;
	if (self)
	{
		// you can do this here specifically or at the table level for all cells
		//self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		unitsSoldLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		unitsSoldLabel.backgroundColor = [UIColor clearColor];
		//unitsSoldLabel.opaque = NO;
		//unitsSoldLabel.textColor = [UIColor blackColor];
		unitsSoldLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		unitsSoldLabel.textAlignment = UITextAlignmentCenter;
		unitsSoldLabel.adjustsFontSizeToFitWidth = YES;
		unitsSoldLabel.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		[self.contentView addSubview:unitsSoldLabel];

		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		royaltyEarnedLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		royaltyEarnedLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		royaltyEarnedLabel.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		royaltyEarnedLabel.textAlignment = UITextAlignmentRight;
		[self.contentView addSubview:royaltyEarnedLabel];

		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		unitsUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		unitsUpdatedLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		unitsUpdatedLabel.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		unitsUpdatedLabel.textAlignment = UITextAlignmentCenter;
		unitsUpdatedLabel.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:unitsUpdatedLabel];

		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		unitsRefundedLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		unitsRefundedLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		unitsRefundedLabel.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		unitsRefundedLabel.textAlignment = UITextAlignmentCenter;
		unitsRefundedLabel.adjustsFontSizeToFitWidth = YES;
		unitsRefundedLabel.textColor = [UIColor redColor];
		[self.contentView addSubview:unitsRefundedLabel];

		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		countryCodeLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		countryCodeLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		countryCodeLabel.font = [UIFont systemFontOfSize:8.0];
		countryCodeLabel.backgroundColor = [UIColor clearColor];
		countryCodeLabel.textAlignment = UITextAlignmentCenter;
		[self.contentView addSubview:countryCodeLabel];
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	
	//double column_width = (contentRect.size.width - LEFT_COLUMN_OFFSET - 10.0)/4.0;
	
	// In this example we will never be editing, but this illustrates the appropriate pattern
    CGRect frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, contentRect.origin.y, 45.0,  contentRect.size.height);
	unitsSoldLabel.frame = frame;

	frame.origin.x += frame.size.width;
	frame.size.width = 35.0;
	unitsRefundedLabel.frame = frame;
	
	frame.origin.x += frame.size.width;
	frame.size.width = 90.0;
	royaltyEarnedLabel.frame = frame;

	frame.origin.x += frame.size.width;
	frame.size.width = 60.0;
	unitsUpdatedLabel.frame = frame;
	
	frame.origin.x = 9.0;
	frame.origin.y = 35;
	frame.size.width = 30.0;
	frame.size.height = 15.0;
	countryCodeLabel.frame = frame;
}

- (void)dealloc
{
	[unitsSoldLabel release];
	[royaltyEarnedLabel release];
	[unitsUpdatedLabel release];
	[unitsRefundedLabel release];
	
    [super dealloc];
}

@end