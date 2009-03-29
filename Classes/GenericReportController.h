//
//  GenericReportController.h
//  ASiST
//
//  Created by Oliver Drobnik on 29.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Report, App;

@interface GenericReportController : UITableViewController {
	Report *report;
	UIImage *sumImage;
	App *filteredApp;
}

- (id) initWithReport:(Report *)aReport;

@property (nonatomic, retain) App *filteredApp;

@end
