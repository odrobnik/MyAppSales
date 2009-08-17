//
//  ReportAppsController.h
//  ASiST
//
//  Created by Oliver Drobnik on 02.02.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Report;

@interface ReportAppsController : UITableViewController {
	Report *report;
	UIImage *sumImage;
}

@property (nonatomic, retain) Report *report;


- (id)initWithReport:(Report *)aReport;

@end
