//
//  ReportRootController.h
//  ASiST
//
//  Created by Oliver Drobnik on 17.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
@class Report;


@interface ReportRootController : UITableViewController {
	UIImage *report_icon;
	UIImage *report_icon_new;

}

- (void)gotoReport:(Report *)reportToShow;
- (void)gotToReportType:(ReportType)typeToShow;

@end
