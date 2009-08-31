//
//  ButtonCell.m
//  ASiST
//
//  Created by Oliver on 24.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "ButtonCell.h"

#define MAIN_FONT_SIZE 16.0


@implementation ButtonCell

@synthesize centerLabel;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = TABLEVIEWCELL_PLAIN_INIT) {
        // Initialization code
		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		centerLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		//titleLabel.backgroundColor = [UIColor clearColor];
		//titleLabel.opaque = NO;
		//titleLabel.textColor = [UIColor blackColor];
		//titleLabel.highlightedTextColor = [UIColor whiteColor];
		centerLabel.textAlignment = UITextAlignmentCenter;
		
		centerLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		centerLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		[self.contentView addSubview:centerLabel];
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
 	
	centerLabel.frame = CGRectInset([self.contentView bounds], 5, 5);
}


- (void)dealloc {
	[centerLabel release];
    [super dealloc];
}


@end
