//
//  EditableCell.m
//  ASiST
//
//  Created by Oliver Drobnik on 14.01.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "EditableCell.h"
#import "KeychainWrapper.h"
#import "ASiSTAppDelegate.h"
#import "SettingsViewController.h"



#define MAIN_FONT_SIZE 16.0
#define LEFT_COLUMN_OFFSET 10.0

@implementation EditableCell

@synthesize titleLabel, textField;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        // Initialization code
		self.accessoryType = UITableViewCellAccessoryNone;
		self.selectionStyle = UITableViewCellSelectionStyleNone;

		// these are set if the contents need to be saved to keychain
		secKey = nil;
		keychain = nil;
		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		//titleLabel.backgroundColor = [UIColor clearColor];
		//titleLabel.opaque = NO;
		//titleLabel.textColor = [UIColor blackColor];
		//titleLabel.highlightedTextColor = [UIColor whiteColor];
		titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		titleLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		[self.contentView addSubview:titleLabel];
		
		/*
		CGRect frame = CGRectMake(0.0, 0.0, kTextFieldWidth, kTextFieldHeight);
		UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];
		
		returnTextField.borderStyle = UITextBorderStyleBezel;
		returnTextField.textColor = [UIColor blackColor];
		returnTextField.font = [UIFont systemFontOfSize:17.0];
		returnTextField.placeholder = @"<enter text>";
		returnTextField.backgroundColor = [UIColor whiteColor];
		returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
		
		returnTextField.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
		returnTextField.returnKeyType = UIReturnKeyDone;
		
		returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
		
		return returnTextField;
		*/

		
		textField = [[UITextField alloc] initWithFrame:CGRectZero];
		textField.textColor = [UIColor colorWithRed:12850./65535 green:20303./65535 blue:34181./65535 alpha:1.0];
		textField.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		textField.autocorrectionType = UITextAutocorrectionTypeNo;
		textField.keyboardType = UIKeyboardTypeDefault;	// use the default type input method (entire keyboard)
		textField.returnKeyType = UIReturnKeyDone;
		//textField.exclusiveTouch = YES;
		//self.exclusiveTouch = YES;
		
		//textField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
		textField.delegate = self;
		[self.contentView addSubview:textField];
    }
    return self;
}

/*
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
*/

- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	
	NSString *text = titleLabel.text;
	CGSize sizeNecessary = [text sizeWithFont:[UIFont systemFontOfSize:MAIN_FONT_SIZE]];
	
    CGRect frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET , contentRect.origin.y,  sizeNecessary.width+20.0,  contentRect.size.height);
	titleLabel.frame = frame;
	
	frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET + sizeNecessary.width + 20.0 ,contentRect.origin.y+(contentRect.size.height-sizeNecessary.height)/2.0, 
					   contentRect.size.width -  sizeNecessary.width - 2.0*LEFT_COLUMN_OFFSET - 20.0, sizeNecessary.height);
	textField.frame = frame;
}




- (void)dealloc {
	[keychain release];
	[titleLabel dealloc];
	[textField dealloc];
    [super dealloc];
}

- (void) hideKeyboard
{
	[textField resignFirstResponder];
}

- (void) setSecKey:(id)key forKeychain:(KeychainWrapper *) chain;
{
	secKey = key;
	keychain = [chain retain];
	self.textField.text = [keychain objectForKey:secKey];
}

#pragma mark Text Field
- (BOOL)textFieldShouldReturn:(UITextField *)atextField
{
	// on return key we send away the keyboard
	[self hideKeyboard];
	return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	((UITableView*)[self superview]).scrollEnabled = NO;
	//ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	//appDelegate.settingsViewController.tableView.scrollEnabled = NO;	
}

// saving here occurs both on return key and changing away
- (void)textFieldDidEndEditing:(UITextField *)textField
{
	//ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	//appDelegate.settingsViewController.tableView.scrollEnabled = YES;	
	((UITableView*)[self superview]).scrollEnabled = YES;
	if (keychain&&secKey)
	{
		if (self.textField.text)
		{
			[keychain setObject:self.textField.text forKey:secKey];
		}
	}
}	




@end
