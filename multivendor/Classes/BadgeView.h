//
//  BadgeView.h
//  ASiST
//
//  Created by Oliver on 15.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BadgeView : UIView {
	UIImageView *backgroundView;
	UILabel *textLabel;
	
	NSString *text;
}

@property (nonatomic, retain) UIImageView *backgroundView;
@property (nonatomic, retain) UILabel *textLabel;

@property (nonatomic, retain) NSString *text;

@end
