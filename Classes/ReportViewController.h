//
//  ReportViewController.h
//  ASiST
//
//  Created by Oliver Drobnik on 26.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "iTunesConnect.h"  // for ReportType

@interface ReportViewController : UITableViewController {

	//IBOutlet UINavigationController *navigationController;
	
	UIImage *report_icon;
	UIImage *report_icon_new;
	
	NSMutableArray *report_array;
	
	ReportType report_type;
	
	UITabBarItem *tabBarItem;
	
	
	// index by year/month
	
	NSMutableDictionary *indexByYearMonth;
	NSArray *indexByYearMonthSortedKeys;
}

- (id)initWithReportArray:(NSArray *)array reportType:(ReportType)type style:(UITableViewStyle)style;


@property (nonatomic, retain) NSMutableArray *report_array;
@property (nonatomic, retain) UITabBarItem *tabBarItem;

@end
