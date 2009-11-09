//
//  AppDetailViewController.h
//  ASiST
//
//  Created by Oliver on 13.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@class App;

@interface AppDetailViewController : UITableViewController <MFMailComposeViewControllerDelegate>
{
	App *myApp;
}

@property (nonatomic, retain) App *myApp;

- (id) initForApp:(App *)app;

@end
