//
//  TableListSelectorView.h
//  ASiST
//
//  Created by Oliver on 15.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TableListSelectorDelegate <NSObject>

@optional

- (void) didFinishSelectingFromTableListIndex:(NSInteger)index;

@end



@interface TableListSelectorView : UITableViewController 
{
	NSInteger selectedIndex;
	NSArray *myList;
	id <TableListSelectorDelegate> delegate;
}

@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) id <TableListSelectorDelegate> delegate;

- (id) initWithList:(NSArray *)list;

@end
