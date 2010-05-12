//
//  ReportRootController.h
//  ASiST
//
//  Created by Oliver Drobnik on 17.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
@class Report_v1;


@interface ReportRootController : UITableViewController {
	UIImage *report_icon;
	UIImage *report_icon_new;
	
	UIBarButtonItem* reloadButtonItem;
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem* reloadButtonItem;


- (void)gotoReport:(Report_v1 *)reportToShow;
- (void)gotToReportType:(ReportType)typeToShow;

- (IBAction)reloadReports:(id)sender;

@end
