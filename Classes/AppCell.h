//
//  AppCell.h
//  ASiST
//
//  Created by Oliver Drobnik on 12.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class App;

@interface AppCell : UITableViewCell {
	UILabel *appTitleLabel;
	UILabel *subTextLabel;
	
	App* app;
}

@property (nonatomic, retain) App *app;

@end
