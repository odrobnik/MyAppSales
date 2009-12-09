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
#import "PullToRefreshTableViewController.h"


@class App;

@interface AppDetailViewController : PullToRefreshTableViewController <MFMailComposeViewControllerDelegate>
{
	App *myApp;
	UIBarButtonItem *forwardButtonItem;
	UIBarButtonItem *reloadButtonItem;
	
	NSArray *sortedReviews;
	
}

@property (nonatomic, retain) App *myApp;

- (id) initForApp:(App *)app;

@end
