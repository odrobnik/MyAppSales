//
//  LegendView.h
//  ASiST
//
//  Created by Oliver Drobnik on 22.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LegendView : UIView 
{
	double required_height;
}

@property(nonatomic, assign) double required_height;

- (id)initWithFrame:(CGRect)frame Data:(NSDictionary *)data;

- (void)setColorForLabel:(UILabel *)aLabel fromIndex:(NSInteger)idx;

@end
