//
//  AccountTypeSelector.h
//  ASiST
//
//  Created by Oliver on 25.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditAccountController.h"

@interface AccountTypeSelector : UITableViewController {
	id<EditAccountDelegate> delegate;
}

@property (nonatomic, assign) id<EditAccountDelegate> delegate;

@end
