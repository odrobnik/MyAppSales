//
//  EditAccountController.h
//  ASiST
//
//  Created by Oliver on 08.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditableCell.h"

@class Account;


@protocol EditAccountDelegate <NSObject>

@optional

- (void) deleteAccount:(Account *)deletedAccount;
- (void) insertedAccount:(Account *)insertedAccount;

@end



@interface EditAccountController : UITableViewController <EditableCellDelegate>
{
	Account *myAccount;
	id<EditAccountDelegate> delegate;
	
	
	UITextField *accountField;
	UITextField *passwordField;
	UITextField *descriptionField;
	
}

@property (nonatomic, retain) Account *myAccount;
@property (nonatomic, assign) id<EditAccountDelegate> delegate;

- (id) initWithAccount:(Account *)account;

@end
