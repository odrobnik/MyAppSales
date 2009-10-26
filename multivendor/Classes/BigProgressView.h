//
//  BigProgressView.h
//  ELO
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GrayRoundRectView;

@interface BigProgressView : UIView 
{
	UIActivityIndicatorView *actView;
	GrayRoundRectView *grayView;
	UIView *backgroundView;
	
	UILabel *textLabel;
	UIProgressView *progressView;
	
}

@property(nonatomic, retain) UILabel *textLabel;

- (void) startAnimatingOverView:(UIView *)blockedView;
- (void) stopAnimating;

- (void) setProgressPercent:(double)percent;

@end
