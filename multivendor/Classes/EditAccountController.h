//
//  EditAccountController.h
//  ASiST
//
//  Created by Oliver on 08.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditableCell.h"

#import "Account+MyAppSales.h"


@protocol EditAccountDelegate <NSObject>

@optional

- (void) deleteAccount:(Account *)deletedAccount;
- (void) insertedAccount:(Account *)insertedAccount;
- (void) modifiedAccount:(Account *)modifiedAccount;

@end

@class BigProgressView;

@interface EditAccountController : UITableViewController <EditableCellDelegate>
{
	Account *myAccount;
	id<EditAccountDelegate> delegate;
	
	
	UITextField *accountField;
	UITextField *passwordField;
	UITextField *descriptionField;
	
	AccountType typeForNewAccount;
	
	BigProgressView *prog;
}

@property (nonatomic, retain) Account *myAccount;
@property (nonatomic, assign) id<EditAccountDelegate> delegate;
@property (nonatomic, assign) AccountType typeForNewAccount;

- (id) initWithAccount:(Account *)account;

@end
