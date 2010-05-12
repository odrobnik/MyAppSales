//
//  ReportAppsController.h
//  ASiST
//
//  Created by Oliver Drobnik on 02.02.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Report_v1;

@interface ReportAppsController : UITableViewController {
	Report_v1 *report;
	UIImage *sumImage;
	
	UISegmentedControl *segmentedControl;
	NSArray *sortedApps;
}

@property (nonatomic, retain) Report_v1 *report;


- (id)initWithReport:(Report_v1 *)aReport;

@end
