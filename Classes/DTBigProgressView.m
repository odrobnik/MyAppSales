//
//  DTBigProgressView.m
//  ELO
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "DTBigProgressView.h"
#import "GrayRoundRectView.h"

#define PROGRESS_WIDTH 150.0
#define PROGRESS_HEIGHT 150.0



@interface DTBigProgressView () // private

@property(nonatomic, retain) UILabel *textLabel;

@end



@implementation DTBigProgressView

@synthesize text, textLabel, resultImage, fadeOutDelay;

- (id)initWithWindow:(UIWindow *)window 
{
	CGRect frame = window.bounds;
	_windowToBlock = window;
	
	
	if (self = [super initWithFrame:frame]) 
	{
		// whole window darkening view
		
		self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
		self.userInteractionEnabled = YES;
		self.exclusiveTouch = YES;
		
		CGRect grayViewRect = CGRectMake((frame.size.width - PROGRESS_WIDTH)/2.0, 
										 (frame.size.height - PROGRESS_HEIGHT)/2.0,
										 PROGRESS_WIDTH, PROGRESS_HEIGHT);
		grayView = [[GrayRoundRectView  alloc] initWithFrame:grayViewRect];
		[self addSubview:grayView];
		
		
		actView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] retain];
		CGSize actSize = [actView sizeThatFits:CGSizeZero];
		actView.frame = CGRectMake((grayView.bounds.size.width - actSize.width)/2.0, 
								   (grayView.bounds.size.height - actSize.height)/2.0,
								   actSize.width, actSize.height);
		actView.hidesWhenStopped = YES;
		[grayView addSubview:actView];
		
		
		
		
		textLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, grayView.frame.size.height - 25.0, 
															  grayView.frame.size.width-10.0,
															  20.0)];
		[grayView addSubview:textLabel];
		textLabel.text = @"Please wait ...";
		textLabel.textColor = [UIColor whiteColor];
		textLabel.shadowColor = [UIColor blackColor];
		textLabel.shadowOffset = CGSizeMake(1, 1);
		textLabel.font = [UIFont systemFontOfSize:13.0];
		textLabel.backgroundColor = [UIColor clearColor];
		textLabel.textAlignment = UITextAlignmentCenter;
		textLabel.adjustsFontSizeToFitWidth = YES;
		textLabel.minimumFontSize = 8.0;
		
		self.opaque = NO;
		
		// fadeout default
		fadeOutDelay = 2.0;
		
		// can also fade out via notification
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideNotification:) name:@"DTBigProgressHideNotification" object:nil];
    }
    return self;
}


- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[textLabel release];
	[grayView release];
	[actView release];
	
	[text release];
	[resultImage release];
	
    [super dealloc];
}

#pragma mark Properties

- (void) setText:(NSString *)newText
{
	if (text != newText)
	{
		[text release];
	}
	text = [newText retain];
	
	textLabel.text = text;
}


#pragma mark Showing / Hiding
- (void) animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	[self removeFromSuperview];
}


- (void)hide
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationBeginsFromCurrentState:YES];

	//[UIView setAnimationDuration:2.0];
	
	grayView.transform = CGAffineTransformMakeScale(1.3, 1.3);
	self.alpha = 0;
	
	[UIView commitAnimations];	
}

- (void)hideAfterDelay
{
	if (fadeOutDelay>0)
	{
		[self performSelector:@selector(hide) withObject:nil afterDelay:fadeOutDelay];
	}
	else 
	{
		[self performSelector:@selector(hide) withObject:nil afterDelay:0.5];
	}
}

- (void)show:(BOOL)show
{
	_isShowing = show;
	
	if (show)
	{
		[_windowToBlock addSubview:self];
		
		grayView.transform = CGAffineTransformMakeScale(0.7, 0.7);
		self.alpha = 0;
	
		UIView *imageView = [grayView viewWithTag:1];
		if (imageView)
		{
			[imageView removeFromSuperview];
		}
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
	
		grayView.transform = CGAffineTransformIdentity;
		self.alpha = 1;
	
		[UIView commitAnimations];
		[actView startAnimating];
	}
	else
	{
		grayView.transform = CGAffineTransformIdentity;
		[actView stopAnimating];
		
		if (resultImage)
		{
			UIImageView *imageView = [[UIImageView alloc] initWithImage:resultImage];
			imageView.center = actView.center;
			imageView.tag = 1;
			[grayView addSubview:imageView];
			[imageView release];
		}
		self.alpha = 1;

		
		[self performSelectorOnMainThread:@selector(hideAfterDelay) withObject:nil waitUntilDone:NO];
	}
}

#pragma mark Hiding via Notification
- (void)hideNotification:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	
	if (userInfo)
	{
		UIImage *infoResultImage = [userInfo objectForKey:@"ResultImage"];
		
		if (infoResultImage)
		{
			self.resultImage = infoResultImage;
		}
		
		NSNumber *fadeoutDelayNum = [userInfo objectForKey:@"FadeOutDelay"];
		
		if (fadeoutDelayNum)
		{
			self.fadeOutDelay = [fadeoutDelayNum doubleValue];
		}
	}
	
	[self show:NO];
}


+ (DTBigProgressView *)progressFromWindow:(UIWindow *)window
{
	return [[[DTBigProgressView alloc] initWithWindow:window] autorelease];
}


+ (void)hideAnyProgressViewWithImage:(UIImage *)image afterDelay:(NSTimeInterval)delay
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	
	if (image)
	{
		[userInfo setObject:image forKey:@"ResultImage"];
	}
	
	if (delay>0)
	{
		[userInfo setObject:[NSNumber numberWithDouble:delay] forKey:@"FadeOutDelay"];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DTBigProgressHideNotification" object:nil userInfo:userInfo];
}


@end
