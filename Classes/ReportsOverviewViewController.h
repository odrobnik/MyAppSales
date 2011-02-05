//
//  ReportsOverviewViewController.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 05.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ProductGroup.h"
#import "ReportTypes.h"


@interface ReportsOverviewViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
	ProductGroup *_productGroup;
	ReportType _reportType;
	
	NSFetchedResultsController *fetchedResultsController;
	
	NSDateFormatter *cellDateFormatter;
	NSDateFormatter *sectionNameDateFormatter;
	NSDateFormatter *sectionNameDateParser;
}

- (id)initWithProductGroup:(ProductGroup *)productGroup reportType:(ReportType)reportType;

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
