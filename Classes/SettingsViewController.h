//
//  SettingsViewController.h
//  ASiST
//
//  Created by Oliver Drobnik on 14.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditAccountController.h"
#import "PinLockController.h"

//@class KeychainWrapper;

@interface SettingsViewController : UITableViewController <UIActionSheetDelegate, EditAccountDelegate, PinLockDelegate> {
	//KeychainWrapper *keychainWrapper;
	
	BOOL showAddress;
}

//@property (nonatomic, retain) KeychainWrapper *keychainWrapper;

- (void) selectionChanged:(NSString *)newSel;

- (IBAction) showAppInfo:(id)sender;

- (void)serverStatusChanged:(NSNotification *) notification;



@end
