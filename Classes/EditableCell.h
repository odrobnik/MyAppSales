//
//  EditableCell.h
//  ASiST
//
//  Created by Oliver Drobnik on 14.01.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KeychainWrapper;

@interface EditableCell : UITableViewCell <UITextFieldDelegate> {
	UILabel *titleLabel;
	UITextField *textField;
	KeychainWrapper *keychain;
	id secKey;
}

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UITextField *textField;

- (void) hideKeyboard;

- (void) setSecKey:(id)key forKeychain:(KeychainWrapper *) chain;

@end
