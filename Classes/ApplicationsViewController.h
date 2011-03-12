//
//  ApplicationsViewController.h
//  ASiST
//
//  Created by Oliver on 27.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDatabase.h"


@interface ApplicationsViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *fetchedResultsController;
	
	BOOL ignoreFetchedResultControllerNotifications;

}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;


@end
