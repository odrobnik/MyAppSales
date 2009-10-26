//
//  AppCell.h
//  ASiST
//
//  Created by Oliver Drobnik on 12.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class App, BadgeView;

@interface AppCell : UITableViewCell {
	UILabel *appTitleLabel;
	UILabel *subTextLabel;
	UILabel *royaltiesLabel;
	UILabel *totalUnitsLabel;
	BadgeView *badge;
	
	App* app;
}

@property (nonatomic, retain) App *app;

@end
