//
//  EditAccountController.h
//  ASiST
//
//  Created by Oliver on 08.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditableCell.h"

#import "GenericAccount+MyAppSales.h"


@protocol EditAccountDelegate <NSObject>

@optional

- (void) deleteAccount:(GenericAccount *)deletedAccount;
- (void) insertedAccount:(GenericAccount *)insertedAccount;
- (void) modifiedAccount:(GenericAccount *)modifiedAccount;

@end

@class DTBigProgressView;

@interface EditAccountController : UITableViewController <EditableCellDelegate>
{
	GenericAccount *myAccount;
	id<EditAccountDelegate> delegate;
	
	
	UITextField *accountField;
	UITextField *passwordField;
	UITextField *descriptionField;
	
	GenericAccountType typeForNewAccount;
	
	DTBigProgressView *prog;
}

@property (nonatomic, retain) GenericAccount *myAccount;
@property (nonatomic, assign) id<EditAccountDelegate> delegate;
@property (nonatomic, assign) GenericAccountType typeForNewAccount;

- (id) initWithAccount:(GenericAccount *)account;

@end
