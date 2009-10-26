//
//  AppDetailViewController.h
//  ASiST
//
//  Created by Oliver on 13.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class App;

@interface AppDetailViewController : UITableViewController 
{
	App *myApp;
}

@property (nonatomic, retain) App *myApp;

- (id) initForApp:(App *)app;

@end
