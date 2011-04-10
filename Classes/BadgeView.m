//
//  BadgeView.m
//  ASiST
//
//  Created by Oliver on 15.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "BadgeView.h"


@implementation BadgeView

@synthesize textLabel, backgroundView, text;


- (id) initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		
		UIImage *image = [UIImage imageNamed:@"Badge.png"];
		UIImage *stretchableImage = [image stretchableImageWithLeftCapWidth:14 topCapHeight:14];
		backgroundView = [[UIImageView alloc] initWithImage:stretchableImage];
		[self addSubview:backgroundView];
		
		textLabel = [[UILabel alloc] initWithFrame:frame];
		textLabel.textColor = [UIColor whiteColor];
		textLabel.backgroundColor = [UIColor clearColor];
		textLabel.textAlignment = UITextAlignmentCenter;
		textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		textLabel.font = [UIFont boldSystemFontOfSize:16.0];
		
		[self addSubview:textLabel];
		
	}
	return self;
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	[self sizeToFit];
	
	CGRect frame = self.bounds;
	
	backgroundView.frame = frame;
	
	frame.size.height-=8.0;
	frame.size.width-=1.0;
	//frame.origin.y-=1.0;
	textLabel.frame = frame;
}

- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize neededSizeToFitText = [textLabel.text sizeWithFont:textLabel.font constrainedToSize:CGSizeMake(textLabel.frame.size.width, 2000.0)];
	
	size.height = neededSizeToFitText.height + 5;
	size.width = neededSizeToFitText.width + 20;
	
	if (size.height<30.0) size.height = 30.0;
	if (size.width<29.0) size.width = 29.0;
	
	return size;
}

- (void) dealloc
{
	[text release];
	[backgroundView release];
	[textLabel release];
	[super dealloc];
}


- (void) setText:(NSString *)newText
{
	if (text==newText) return;
	
	[text release];
	textLabel.text = newText;
	text = [newText retain];
	
	[self layoutSubviews];
}


@end
