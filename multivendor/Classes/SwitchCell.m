//
//  SwitchCell.m
//  ASiST
//
//  Created by Oliver Drobnik on 15.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "SwitchCell.h"

#define MAIN_FONT_SIZE 16.0
#define LEFT_COLUMN_OFFSET 10.0

@implementation SwitchCell

@synthesize switchCtl, titleLabel;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = TABLEVIEWCELL_PLAIN_INIT) {
        // Initialization code
		self.selectionStyle = UITableViewCellSelectionStyleNone;

		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		//titleLabel.backgroundColor = [UIColor clearColor];
		//titleLabel.opaque = NO;
		//titleLabel.textColor = [UIColor blackColor];
		//titleLabel.highlightedTextColor = [UIColor whiteColor];
		titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		titleLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		[self.contentView addSubview:titleLabel];
		
		switchCtl = [[UISwitch alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:switchCtl];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	
	NSString *text = titleLabel.text;
	CGSize sizeNecessary = [text sizeWithFont:[UIFont systemFontOfSize:MAIN_FONT_SIZE]];
	
    CGRect frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET , contentRect.origin.y,  sizeNecessary.width+20.0,  contentRect.size.height);
	titleLabel.frame = frame;
	
	frame = CGRectMake(contentRect.origin.x + contentRect.size.width - 94.0 - LEFT_COLUMN_OFFSET,contentRect.origin.y+(contentRect.size.height-27.0)/2.0, 
					   94.0, 27.0);
	switchCtl.frame = frame;
}

- (void)dealloc 
{
	[titleLabel release];
	[switchCtl release];
    [super dealloc];
}


@end
