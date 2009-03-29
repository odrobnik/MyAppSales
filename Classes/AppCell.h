//
//  AppCell.h
//  ASiST
//
//  Created by Oliver Drobnik on 12.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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
