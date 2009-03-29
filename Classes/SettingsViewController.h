//
//  SettingsViewController.h
//  ASiST
//
//  Created by Oliver Drobnik on 14.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KeychainWrapper;

@interface SettingsViewController : UITableViewController {
	KeychainWrapper *keychainWrapper;
	
	BOOL showAddress;
}

@property (nonatomic, retain) KeychainWrapper *keychainWrapper;

- (void) selectionChanged:(NSString *)newSel;

- (IBAction) showAppInfo:(id)sender;

- (void)serverStatusChanged:(NSNotification *) notification;



@end
