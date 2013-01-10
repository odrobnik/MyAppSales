//
//  BigProgressView.m
//  ELO
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "BigProgressView.h"
#import "GrayRoundRectView.h"

#define PROGRESS_WIDTH 100.0
#define PROGRESS_HEIGHT 100.0


@implementation BigProgressView

@synthesize textLabel;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		
		//CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		
		
		// whole window darkening view
		
		backgroundView = [[UIView alloc] initWithFrame:self.bounds];
		backgroundView.opaque = NO;
		backgroundView.alpha = 0.2;
		backgroundView.backgroundColor = [UIColor blackColor];
		[self addSubview:backgroundView];
		
		CGRect grayViewRect = CGRectMake((frame.size.width - PROGRESS_WIDTH)/2.0, 
										 (frame.size.height - PROGRESS_HEIGHT)/2.0,
										 PROGRESS_WIDTH, PROGRESS_HEIGHT);
		grayView = [[GrayRoundRectView  alloc] initWithFrame:grayViewRect];
		[self addSubview:grayView];
		
		actView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] retain];
		CGSize actSize = [actView sizeThatFits:CGSizeZero];
		actView.frame = CGRectMake((frame.size.width - actSize.width)/2.0, 
								   (frame.size.height - actSize.height)/2.0,
								   actSize.width, actSize.height);
		[self addSubview:actView];
		[actView startAnimating];
		
		
		
		textLabel = [[UILabel alloc] initWithFrame:CGRectMake(grayView.frame.origin.x, 
															  grayView.frame.origin.y, 
																	   grayView.frame.size.width,
																	   20.0)];
		[self addSubview:textLabel];
		textLabel.text = NSLocalizedString(@"Loading", @"Progress");
		textLabel.textColor = [UIColor whiteColor];
		textLabel.shadowColor = [UIColor blackColor];
		textLabel.shadowOffset = CGSizeMake(1, 1);
		textLabel.font = [UIFont systemFontOfSize:10.0];
		textLabel.backgroundColor = [UIColor clearColor];
		textLabel.textAlignment = UITextAlignmentCenter;
		
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.alpha = 0;
		
		progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		progressView.frame = CGRectMake(grayView.frame.origin.x + 5.0, grayView.frame.origin.y + grayView.frame.size.height - 20.0, 
																						  grayView.frame.size.width - 10.0,
																						  20.0);
		progressView.alpha = 0;
		
		[self addSubview:progressView];
		
		grayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	CGRect frame = self.bounds;
	
	CGRect grayViewRect = CGRectMake((frame.size.width - PROGRESS_WIDTH)/2.0,
									 (frame.size.height - PROGRESS_HEIGHT)/2.0,
									 PROGRESS_WIDTH, PROGRESS_HEIGHT);
	grayView.frame = grayViewRect;
	
	CGSize actSize = [actView sizeThatFits:CGSizeZero];
	actView.frame = CGRectMake((frame.size.width - actSize.width)/2.0,
							   (frame.size.height - actSize.height)/2.0,
							   actSize.width, actSize.height);
	
	CGRect textFrame = CGRectMake(grayView.frame.origin.x, 
								  grayView.frame.origin.y, 
								  grayView.frame.size.width,
								  20.0);
	textLabel.frame = textFrame;
	
	progressView.frame = CGRectMake(grayView.frame.origin.x + 5.0, grayView.frame.origin.y + grayView.frame.size.height - 20.0, 
									grayView.frame.size.width - 10.0,
									20.0);
}

- (void) startAnimatingOverView:(UIView *)blockedView
{
	self.frame = blockedView.bounds;
	[blockedView addSubview:self];
	
	//prog.contentMode = UIViewContentModeCenter;
	//self.view.contentMode = UIViewContentModeCenter;
	self.autoresizesSubviews = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;	
	// invisible start settings
	grayView.transform = CGAffineTransformMakeScale(0.5, 0.5);
	self.alpha = 0;
	backgroundView.alpha = 0;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	grayView.transform = CGAffineTransformIdentity;
	self.alpha = 1;
	backgroundView.alpha = 0.2;
	
	[UIView commitAnimations];
	[actView startAnimating];
}

- (void) stopAnimating
{
	// invisible start settings
	grayView.transform = CGAffineTransformIdentity;
	self.alpha = 1;
	backgroundView.alpha = 0.2;
	
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	grayView.transform = CGAffineTransformMakeScale(1.5, 1.5);
	self.alpha = 0;
	backgroundView.alpha = 0;
	
	progressView.alpha = 0;

	
	[UIView commitAnimations];
	[actView startAnimating];
	
	[self removeFromSuperview];
	
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}


- (void)dealloc {
	[progressView release];
	[textLabel release];
	[backgroundView release];
	[grayView release];
	
	[actView release];
    [super dealloc];
}


#pragma mark Progress Bar
- (void) setProgressPercent:(double)percent
{
	progressView.progress = percent;
	progressView.alpha = 1;
}


@end
