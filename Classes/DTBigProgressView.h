//
//  DTBigProgressView.h
//  ELO
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GrayRoundRectView;

@interface DTBigProgressView : UIView 
{
	UIActivityIndicatorView *actView;
	GrayRoundRectView *grayView;
	UILabel *textLabel;
	NSString *text;
	UIWindow *_windowToBlock;
	
	UIImage *resultImage;
	
	NSTimeInterval fadeOutDelay;
	
	BOOL _isShowing;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) UIImage *resultImage;
@property (nonatomic) NSTimeInterval fadeOutDelay;


- (id)initWithWindow:(UIWindow *)window;
- (void)show:(BOOL)show; 

+ (DTBigProgressView *)progressFromWindow:(UIWindow *)window;
+ (void)hideAnyProgressViewWithImage:(UIImage *)image afterDelay:(NSTimeInterval)delay;



@end
