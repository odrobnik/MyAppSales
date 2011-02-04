//
//  ApplicationReviewsViewController.h
//  ASiST
//
//  Created by Oliver on 27.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDatabase.h"
#import "PullToRefreshTableViewController.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface ApplicationReviewsViewController : PullToRefreshTableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *fetchedResultsController;
	
	Product *_product;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) Product *product;


- (id)initWithProduct:(Product *)product;

@end
