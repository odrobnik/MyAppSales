//
//  PushButtonCell.h
//  ASiST
//
//  Created by Oliver on 08.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PushButtonCell : UITableViewCell 
{
	UIButton *button;
	NSString *title;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) UIButton *button;

@end