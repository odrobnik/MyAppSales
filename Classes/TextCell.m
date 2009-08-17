//
//  TextCell.m
//  iWoman
//
//  Created by Oliver Drobnik on 18.09.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "TextCell.h"


@implementation TextCell

@synthesize title;
@synthesize value;

#define LEFT_COLUMN_OFFSET		10.0
#define LEFT_COLUMN_WIDTH		200.0
#define RIGHT_COLUMN_OFFSET 152.0
#define RIGHT_COLUMN_WIDTH 140.0
#define MAIN_FONT_SIZE 16.0


- (id)initWithFrame:(CGRect)aRect reuseIdentifier:identifier
{
	self = [super initWithFrame:aRect reuseIdentifier:identifier];
	if (self)
	{
		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryNone;
		self.selectionStyle = UITableViewCellSelectionStyleBlue;
		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		title = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		//title.backgroundColor = [UIColor clearColor];
		title.opaque = YES;
		title.textColor = [UIColor blackColor];
		title.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		title.highlightedTextColor = [UIColor whiteColor];
		title.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		[self.contentView addSubview:title];
		
		value = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		//value.backgroundColor = [UIColor clearColor];
		value.opaque = YES;
		value.textColor = [UIColor colorWithRed:12850./65535 green:20303./65535 blue:34181./65535 alpha:1.0];
		value.highlightedTextColor = [UIColor whiteColor];
		value.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		value.textAlignment = UITextAlignmentRight;
		value.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		[self.contentView addSubview:value];
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	
	// In this example we will never be editing, but this illustrates the appropriate pattern
    CGRect frame =  CGRectMake(contentRect.origin.x+LEFT_COLUMN_OFFSET,  contentRect.origin.y, LEFT_COLUMN_WIDTH, contentRect.size.height);
	if (self.image)
	{
		frame.origin.x += self.image.size.width + LEFT_COLUMN_OFFSET;
		frame.size.width -= self.image.size.width + LEFT_COLUMN_OFFSET;
	}
	title.frame = frame;
	
	NSString *text = value.text;
	CGSize sizeNecessary = [text sizeWithFont:[UIFont systemFontOfSize:MAIN_FONT_SIZE]];

	frame = CGRectMake(contentRect.size.width -  sizeNecessary.width - 15.0,  contentRect.origin.y, sizeNecessary.width + 5.0, contentRect.size.height);
	value.frame = frame;
}

- (void)dealloc
{
	[title release];
	[value release];
	
    [super dealloc];
}

@end