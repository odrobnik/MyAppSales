//
//  EditableCell.h
//  ASiST
//
//  Created by Oliver Drobnik on 14.01.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KeychainWrapper, EditableCell;

@protocol EditableCellDelegate <NSObject>

@optional

- (void) editableCell:(EditableCell *)editableCell textChangedTo:(NSString *)newText;

@end




@interface EditableCell : UITableViewCell <UITextFieldDelegate> {
	
	id<EditableCellDelegate> delegate;
	UILabel *titleLabel;
	UITextField *textField;
	KeychainWrapper *keychain;
	id secKey;
}

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, assign) id<EditableCellDelegate> delegate;


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void) hideKeyboard;

- (void) setSecKey:(id)key forKeychain:(KeychainWrapper *) chain;

@end
