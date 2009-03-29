//
//  AxisView.h
//  ASiST
//
//  Created by Oliver Drobnik on 21.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AxisView : UIView {
	double max;
	NSString *currency;
	double bottom_inset;
	
	CGPoint offset;
	float scale;
}

@property (nonatomic, retain) NSString *currency;
@property (nonatomic, assign) double bottom_inset;

@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, assign) float scale;

- (id)initWithFrame:(CGRect)frame  max:(double)max_value currency:(NSString *)cur;

@end
