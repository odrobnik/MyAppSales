//
//  ApplicationCell.h
//  ASiST
//
//  Created by Oliver on 27.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BadgeView.h"

@interface ApplicationCell : UITableViewCell 
{
	UILabel *appTitleLabel;
	UILabel *subTextLabel;
	UILabel *royaltiesLabel;
	UILabel *totalUnitsLabel;
	BadgeView *badge;
}

@property (nonatomic, retain) UILabel *appTitleLabel;
@property (nonatomic, retain) UILabel *subTextLabel;
@property (nonatomic, retain) UILabel *royaltiesLabel;
@property (nonatomic, retain) UILabel *totalUnitsLabel;
@property (nonatomic, retain) BadgeView *badge;


@end
