//
//  ButtonCell.m
//  ELO
//
//  Created by Oliver on 06.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "PushButtonCell.h"


@implementation PushButtonCell

@synthesize title, button;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        // Initialization code
		
		button = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		
		/*Set button background and scale it to fit the frame we set*/
		//[button setBackgroundImage: [[UIImage imageNamed: @"redButton.png"] stretchableImageWithLeftCapWidth:7.0 topCapHeight:0.0] forState:UIControlStateNormal];
		[button setBackgroundImage: [UIImage imageNamed: @"button_red.png"] forState:UIControlStateNormal];
		button.titleLabel.shadowColor = [UIColor lightGrayColor];
		button.titleLabel.shadowOffset = CGSizeMake(0, -1);
			
		[self.contentView addSubview:button];
    }
    return self;
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	button.frame = CGRectInset(self.contentView.bounds, 0,-2);
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	
    [super setSelected:selected animated:animated];
	
    // Configure the view for the selected state
}


- (void)dealloc {
	[button release];
	[title release];
    [super dealloc];
}

- (void) setTitle:(NSString *)newTitle
{
	if (newTitle == title) return;
	
	[title release];
	title = [newTitle retain];
	
	[button setTitle:title forState:UIControlStateNormal];
}

@end
