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
- (void) didFinishSelectingFromTableKey:(NSString *)key;
@end



@interface TableListSelectorView : UITableViewController 
{
	NSInteger selectedIndex;
	NSArray *myList;
	NSDictionary *myDictionary;
	
	id <TableListSelectorDelegate> delegate;
}

@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) id <TableListSelectorDelegate> delegate;
//@property (nonatomic, assign) NSString *selectedKey;

- (id) initWithList:(NSArray *)list;
- (id) initWithDictionary:(NSDictionary *)dict;

- (void) setSelectedKey:(NSString *)newKey;


@end
