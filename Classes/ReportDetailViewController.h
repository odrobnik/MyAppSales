//
//  ReportDetailViewController.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 06.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ReportDetailViewController : UITableViewController 
{
	NSArray *_summaries;
	
	NSMutableArray *_childrenSorted;
}

@property (nonatomic, retain) NSArray *summaries;

- (id)initWithSectionSummaries:(NSArray *)summaries;

@end
