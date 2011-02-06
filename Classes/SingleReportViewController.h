//
//  SingleReportViewController.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 05.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CoreDatabase.h"

@interface SingleReportViewController : UITableViewController 
{
	Report *_report;
	
	NSArray *sortedSummaries;
	NSArray *apps;
}

@property (nonatomic, retain) Report *report;

- (id)initWithReport:(Report *)report;

@end
