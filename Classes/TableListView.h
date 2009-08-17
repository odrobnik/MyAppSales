//
//  TableListView.h
//  ASiST
//
//  Created by Oliver Drobnik on 15.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YahooFinance;

@interface TableListView : UITableViewController {
	YahooFinance *myYahoo;
	NSInteger	selectedIndex;

}

@property (nonatomic, retain) YahooFinance *myYahoo;
@property (nonatomic, assign) NSInteger selectedIndex;

// custom constructor
- (id)initWithYahoo:(YahooFinance *)yahoo style:(UITableViewStyle)style;

- (void) setSelectedItem:(NSString *)aText;


@end
