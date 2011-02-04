//
//  ReportsGroupsAndTypeSelectionViewController.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 03.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDatabase.h"

#import "PullToRefreshTableViewController.h"

@interface ReportsGroupsAndTypeSelectionViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
	NSFetchedResultsController *fetchedResultsController;
	
	NSArray *productGroupIndex;
	
	UIBarButtonItem* reloadButtonItem;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, retain) IBOutlet UIBarButtonItem* reloadButtonItem;

@end
