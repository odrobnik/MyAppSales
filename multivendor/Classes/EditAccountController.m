//
//  EditAccountController.m
//  ASiST
//
//  Created by Oliver on 08.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "EditAccountController.h"
#import "Account.h"
#import "Account+MyAppSales.h"
#import "EditableCell.h"
#import "PushButtonCell.h"
#import "AccountManager.h"
#import "BigProgressView.h"


@implementation EditAccountController

@synthesize myAccount, delegate, typeForNewAccount;

- (id) initWithAccount:(Account *)account
{
	if (self = [super initWithStyle:UITableViewStyleGrouped])
	{
		self.myAccount = account;
		
		
		if (!account)
		{
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave 
																								   target:self action:@selector(save:)];
			self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
																								  target:self action:@selector(cancel:)];
			self.navigationItem.rightBarButtonItem.enabled = NO;
			
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(somethingTyped:) name:UITextFieldTextDidChangeNotification object:nil];
			
		}
	}
	
	
	return self;
}

- (void) setupProgressView
{
	prog = [[BigProgressView alloc] initWithFrame:self.view.bounds];  //
	//prog.contentMode = UIViewContentModeCenter;
	//self.view.contentMode = UIViewContentModeCenter;
	prog.autoresizesSubviews = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.view.autoresizesSubviews = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	[self.view addSubview:prog];
}

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 if (self = [super initWithStyle:style]) {
 }
 return self;
 }
 */

/*
 - (void)viewDidLoad {
 [super viewDidLoad];
 
 // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
 // self.navigationItem.rightBarButtonItem = self.editButtonItem;
 }
 */


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	if (!typeForNewAccount&&[myAccount accountType])
	{
		typeForNewAccount = [myAccount accountType];
	}
	
	NSString *accountTypeString = [Account stringForAccountType:typeForNewAccount];
	self.title = accountTypeString;
	
	if (!myAccount)
	{
		self.navigationItem.prompt = [NSString stringWithFormat:@"Enter your %@ account information", accountTypeString];
	}
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	int num = 1;
	if (myAccount)
	{
		num++; // delete button
	}

	
	
    return num;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch (section) {
		case 0:
			return 3;
		case 1:
			return 1;
	}
	
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (!myAccount)
	{
		switch (typeForNewAccount) 
		{
			case AccountTypeITC:
				return @"Downloading sales report directly from your account. Credentials as safely store on your keychain.";
				break;
			case AccountTypeNotifications:
				return @"Notifications is a 3rd party app enabling push notifications for MyAppSales.";
				break;
			default:
				break;
		}
	}
	
	return nil;
	
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    switch (indexPath.section) 
	{
		case 1:
		{
			NSString *CellIdentifier = @"ButtonCell";
			
			PushButtonCell *cell = (PushButtonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[PushButtonCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
				[cell.button addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
			}
			
			cell.title = @"Delete Account";
			
			return cell;
			
			break;
		}
		case 0:
		{
			NSString *CellIdentifier = @"EditCell";
			
			EditableCell *cell = (EditableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[EditableCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
			}
			
			// Set up the cell...
			
			switch (indexPath.row) 
			{
				case 0:
				{
					if ((!myAccount)&&(typeForNewAccount==AccountTypeITC)||([myAccount accountType]==AccountTypeITC))
					{
						cell.titleLabel.text = @"Apple ID";
					}
					else 
					{
						cell.titleLabel.text = @"Login";
					}
					
					if (myAccount)
						cell.textField.text = myAccount.account;
					cell.textField.placeholder = @"oliver@drobnik.com";
					cell.textField.secureTextEntry = NO;
					cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
					cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
					cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
					accountField = cell.textField;
					break;
				}
				case 1:
				{
					cell.titleLabel.text = @"Password";
					if (myAccount)
						cell.textField.text = myAccount.password;
					cell.textField.placeholder = @"Password";
					cell.textField.secureTextEntry = YES;
					cell.textField.keyboardType = UIKeyboardTypeDefault;
					passwordField = cell.textField;
					break;
				}
				case 2:
				{
					cell.titleLabel.text = @"Description";
					if (myAccount)
						cell.textField.text = myAccount.description;
					cell.textField.placeholder = [NSString stringWithFormat:@"My %@ account", [Account stringForAccountType:typeForNewAccount]];
					
					cell.textField.secureTextEntry = NO;
					cell.textField.keyboardType = UIKeyboardTypeDefault;
					descriptionField = cell.textField;
					
					break;
				}
			}
			
			cell.delegate = self;
			cell.textField.tag = indexPath.row;
			
			return cell;			
			break;
		}
	}
	
	return nil;
	
	
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Actions for Edit

- (void) cancel:(id)sender
{
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void) save:(id)sender
{
	EditableCell *accountCell = (EditableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	EditableCell *passwordCell = (EditableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
	EditableCell *descriptionCell = (EditableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
	
	
	NSString *account = accountCell.textField.text;
	NSString *password = passwordCell.textField.text;
	NSString *description = descriptionCell.textField.text;
	
	Account *newAccount = [[AccountManager sharedAccountManager] addAccountForService:[Account stringForAccountType:typeForNewAccount] user:account];
	newAccount.password = password;
	newAccount.description = description;
	
	[self.navigationController dismissModalViewControllerAnimated:YES];
	
	if (delegate && [delegate respondsToSelector:@selector(insertedAccount:)])
	{
		[delegate insertedAccount:newAccount];
	}
}

- (void) delete:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
	
	if (delegate && [delegate respondsToSelector:@selector(deleteAccount:)])
	{
		[delegate deleteAccount:myAccount];
	}
	
}

#pragma mark EditableCell Delegate
- (void) editableCell:(EditableCell *)editableCell textChangedTo:(NSString *)newText
{
	switch (editableCell.textField.tag) 
	{
		case 0:
		{
			myAccount.account = newText;
			
			if (![myAccount.description length])
			{
				myAccount.description = newText;
				descriptionField.text = newText;
				[self.tableView reloadData];
			}
			break;
		}
		case 1:
		{
			myAccount.password = newText;
			break;
		}
		case 2:
		{
			myAccount.description = newText;
			break;
		}
	}
	
	self.navigationItem.rightBarButtonItem.enabled = ([accountField.text length]&&[passwordField.text length]);
	
	if (delegate && [delegate respondsToSelector:@selector(modifiedAccount:)])
	{
		[delegate modifiedAccount:myAccount];
	}
}


- (void) somethingTyped:(NSNotification *)notification
{
	self.navigationItem.rightBarButtonItem.enabled = ([accountField.text length]&&[passwordField.text length]);	
}

//UITextFieldTextDidChangeNotification

@end

