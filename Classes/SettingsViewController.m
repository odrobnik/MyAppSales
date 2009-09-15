//
//  SettingsViewController.m
//  ASiST
//
//  Created by Oliver Drobnik on 14.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "SettingsViewController.h"
#import "EditableCell.h"
#import "SwitchCell.h"
#import "TextCell.h"
#import "ButtonCell.h"
#import "YahooFinance.h"

// for the currency selection
#import "TableListView.h"

// to query currency list
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"

// for login data
#import "iTunesConnect.h"
//#import "KeychainWrapper.h"
#import <Security/Security.h>

#import "AccountManager.h"
#import "Account.h"

#import "EditAccountController.h"
#import "PinLockController.h"
#import "TableListSelectorView.h"



@implementation SettingsViewController

//@synthesize keychainWrapper;

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
	//ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	//self.keychainWrapper = appDelegate.keychainWrapper;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverStatusChanged:) name:@"ServerStatusChanged" object:nil];
	//[self.tableView setEditing:YES animated:NO];

	showAddress = NO;
	
	if (!reviewFrequencyList)
	{
		NSMutableArray *tmpArray = [NSMutableArray arrayWithObjects:@"Every Launch", @"1 Day", nil];
		
		for (int i=2;i<=14;i++)
		{
			[tmpArray addObject:[NSString stringWithFormat:@"%d Days", i]];
		}
			 
		reviewFrequencyList = [[NSArray arrayWithArray:tmpArray] retain];
	}
			 

    [super viewWillAppear:animated];
	[self.tableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated 
{
	/*
	EditableCell *loginCell = (EditableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	EditableCell *passwordCell = (EditableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
	
	NSString *login = loginCell.textField.text;
	NSString *password = passwordCell.textField.text;
	[keychainWrapper setObject:login forKey:(id)kSecAttrAccount];
	[keychainWrapper setObject:password forKey:(id)kSecValueData];
*/
	[super viewWillDisappear:animated];
}

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
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}


/*
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}
*/
 
// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch (section) {
		case 0:  // password
			return [[[AccountManager sharedAccountManager] accounts] count]+1;
		case 1:  // reviews
		{
			if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadReviews"] boolValue])
			{
				return 2;
			}
			else 
			{
				return 1;
			}
		}

		case 2:  // reports
			return 2;
		case 3:  // web server
		{
			return showAddress?2:1;
		}
		case 4:  // pin lock
			return 1;
		case 5:  // maintenance
			return 1;
		default:
			break;
	}
    return 0;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (!section)
	{
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];

		NSDate *lastLogin = appDelegate.itts.lastSuccessfulLoginTime;
		
		if (lastLogin)
		{
			NSDateFormatter *form = [[[NSDateFormatter alloc] init] autorelease];
			[form setDateStyle:NSDateFormatterMediumStyle];
			[form setTimeStyle:NSDateFormatterMediumStyle];
			
			return [NSString stringWithFormat:@"Last login %@", [form stringFromDate:lastLogin]];
		}
		else
		{
			return nil;
		}
	}
	else
		return nil;
}
*/
 
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Accounts";
		case 1:
			return @"Reviews";
		case 2:
			return @"Reports";
		case 3:
			return @"Import/Export Server";
		case 4:
			return @"Security";
		case 5:
			return @"Maintenance";
		default:
			break;
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (!section)
	{
		return @"Only first account is currently used.";
	}
	else {
		return nil;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	//ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];

	switch (indexPath.section) 
	{
		case 0:  // accounts
		{
			NSArray *accounts = [[AccountManager sharedAccountManager] accounts];
			
			if (indexPath.row<([accounts count]))
			{
				// account line
				
				Account *rowAccount = [accounts objectAtIndex:indexPath.row];

				NSString *CellIdentifier = @"AccountCell";
				
				UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
				if (cell == nil) 
				{
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
					cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
				}

				cell.textLabel.text = [rowAccount.description length]?rowAccount.description:rowAccount.account;
				cell.detailTextLabel.text = rowAccount.service;
				
				return cell;
				
			}
			else 
			{
				// Add account
				UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:@"AddCell"] autorelease];
				cell.textLabel.text = @"Add Account...";
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
				return cell;
			}
		}
		case 1:   // reviews
		{
			
			switch (indexPath.row) 
			{
				case 0:
				{
					NSString *CellIdentifier = @"ReviewSwitchSection";
					
					SwitchCell *cell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					if (cell == nil) 
					{
						cell = [[[SwitchCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
						cell.titleLabel.text = @"Download Reviews";
					}
					
					
					cell.switchCtl.on = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadReviews"] boolValue];
					[cell.switchCtl addTarget:self action:@selector(switchReviews:) forControlEvents:UIControlEventValueChanged];
					return cell;
				}
				case 1:
				{
					NSString *CellIdentifier = @"ReviewSection";
					
					UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					if (cell == nil) 
					{
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
						cell.textLabel.text = @"Frequency";
					}
					
					NSUInteger frequencyInt = ([[NSUserDefaults standardUserDefaults] integerForKey:@"ReviewFrequency"]);
					
					cell.detailTextLabel.text = [reviewFrequencyList objectAtIndex:frequencyInt];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

					return cell;

					break;
				}
				default:
					return nil;
					break;
			}
		}
			
		case 2:   // general
		{
			switch (indexPath.row) 
			{
				case 0:
				{
					NSString *CellIdentifier = @"ReportSection";
					
					TextCell *cell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					if (cell == nil) 
					{
						cell = [[[TextCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
					}
					
					cell.title.text = @"Main Currency";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					
					cell.value.text = [[YahooFinance sharedInstance] mainCurrency];
					return cell;		
				}
					
				case 1:
				{
					NSString *CellIdentifier = @"ReportSection2";
					
					SwitchCell *cell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					if (cell == nil) 
					{
						cell = [[[SwitchCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
					}
					
					cell.titleLabel.text = @"Use for all amounts";
					ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
					cell.switchCtl.on = appDelegate.convertSalesToMainCurrency;
					[cell.switchCtl addTarget:self action:@selector(toggleConvert:) forControlEvents:UIControlEventValueChanged];
					return cell;
				}
					
			}
		}
			
		case 3:   // web server
		{
			switch (indexPath.row) {
				case 0:
				{
					NSString *CellIdentifier = @"ServerSectionSwitch";
					
					SwitchCell *cell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					if (cell == nil) 
					{
						cell = [[[SwitchCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
					}
					
					cell.titleLabel.text = @"Enable on WLAN";
					ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
					
					cell.switchCtl.on = appDelegate.serverIsRunning;
					[cell.switchCtl addTarget:appDelegate action:@selector(startStopServer:) forControlEvents:UIControlEventValueChanged];
					return cell;
				}
				case 1:
				{
					NSString *CellIdentifier = @"ServerSectionInfo";
					
					TextCell *cell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					if (cell == nil) 
					{
						cell = [[[TextCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
					}
					
					cell.title.text = @"Address";
					ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];

					
#if TARGET_IPHONE_SIMULATOR
					NSString *curAddress = [appDelegate.addresses objectForKey:@"en1"];
#else
					NSString *curAddress = [appDelegate.addresses objectForKey:@"en0"];
#endif
					NSInteger port = (NSInteger)[appDelegate.httpServer port];
					NSString *portString;
					
					if (port==80)
					{
							portString = @"";  // standard, no need to specify
					}
					else
					{
						portString = [NSString stringWithFormat:@":%d", port]; // non-standard
					}
					
					
					cell.value.text = curAddress?[NSString stringWithFormat:@"http://%@%@", curAddress, portString]:@"WLAN not connected";
					return cell;
				}
				default:
					break;
			}

		}
			
		case 4:   // pin lock
		{
			NSString *CellIdentifier = @"LockSection";
			
			UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) 
			{
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
			}
			
			cell.textLabel.text = @"Passcode Lock";
			
			if ([[NSUserDefaults standardUserDefaults] objectForKey:@"PIN"])
			{
				cell.detailTextLabel.text = @"On";
			}
			else 
			{
				cell.detailTextLabel.text = @"Off";
			}

			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			return cell;
		}
			
		case 5:  // action
		{
			NSString *CellIdentifier = @"ActionsSection";
			
			ButtonCell *cell = (ButtonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) 
			{
				cell = [[[ButtonCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
			}

			cell.centerLabel.text = @"Empty Cache";

			return cell;
		}
			
	}

	//NSLog([indexPath description]);
    return nil;
	}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	switch (indexPath.section) 
	{
		case 0:  // accounts
		{
			NSArray *accounts = [[AccountManager sharedAccountManager] accounts];
			
			if (indexPath.row<([accounts count]))
			{
				// account line
				
				Account *rowAccount = [accounts objectAtIndex:indexPath.row];
				
				EditAccountController *controller = [[EditAccountController alloc] initWithAccount:rowAccount];
				controller.title = @"Edit Account";
				controller.delegate = self;
				[self.navigationController pushViewController:controller animated:YES];
				[controller release];
				
			}
			else 
			{
				// Add account
				EditAccountController *controller = [[EditAccountController alloc] initWithAccount:nil];
				controller.title = @"Add Account";
				controller.delegate = self;
				
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
				navController.navigationBar.barStyle = UIBarStyleBlack;
				[controller release];
				
				[self presentModalViewController:navController animated:YES];
				[navController release];
			}
			

			
			break;
		}
		case 1:  // reviews
		{
			if (!indexPath.row) return;
			
			TableListSelectorView *controller = [[TableListSelectorView alloc] initWithList:reviewFrequencyList];
			controller.title = @"Frequency";
			controller.delegate = self;
			controller.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"ReviewFrequency"];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
			break;
		}
			
		case 2: 
		{
			if (indexPath.row)
				return;
			
			// Navigation logic may go here. Create and push another view controller.
			TableListView *anotherViewController = [[TableListView alloc] initWithYahoo:[YahooFinance sharedInstance] style:UITableViewStylePlain];
			anotherViewController.title = @"Main Currency";
			[anotherViewController setSelectedItem:[[YahooFinance sharedInstance] mainCurrency]];
			[self.navigationController pushViewController:anotherViewController animated:YES];
			[anotherViewController release];
			break;
		}
			
		case 4:
		{
			PinLockControllerMode mode;
			
			if ([[NSUserDefaults standardUserDefaults] objectForKey:@"PIN"])
			{
				mode = PinLockControllerModeRemovePin;
			}
			else
			{
				mode = PinLockControllerModeSetPin;
			}
			
			PinLockController *controller = [[PinLockController alloc] initWithMode:mode];
			controller.delegate = self;
			controller.pin = [[NSUserDefaults standardUserDefaults] objectForKey:@"PIN"];
			
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
			navController.navigationBar.barStyle = UIBarStyleBlack;
			[controller release];
			
			[self presentModalViewController:navController animated:YES];
			[navController release];			
		
			break;
		}
			
		case 5:
		{
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			
			UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Do you really want to empty the cache?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Empty Cache", nil];
			
			[actionSheet showInView:self.view.window];
			[actionSheet release];
			
			break;
			
		}
	}
}



#pragma mark Other Stuff
- (IBAction) showAppInfo:(id)sender
{
	// a convenient method to get to the Info.plist in the app bundle
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];

	// get two items from the dictionary
	NSString *version = [info objectForKey:@"CFBundleVersion"];
	NSString *title = [info objectForKey:@"CFBundleDisplayName"];
	
	UIAlertView *alert = [[UIAlertView alloc] 
						  initWithTitle:[@"About " stringByAppendingString:title]
						  message:[NSString stringWithFormat:@"Version %@\n\n© 2009 Drobnik.com\nAll rights reserved.", version]
						  delegate:self 
						  cancelButtonTitle:@"Dismiss" 
						  otherButtonTitles:@"Contact", nil];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	UIApplication *myApp = [UIApplication sharedApplication];
	
	// cancel button has index 0
	switch (buttonIndex) {
		case 1:
		{
			[myApp openURL:[NSURL URLWithString:@"mailto:oliver@drobnik.com"]];
			break;
		}
		default:
			break;
	}
	
}




- (IBAction)toggleConvert:(id)sender
{
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.convertSalesToMainCurrency = [sender isOn];
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

- (void) selectionChanged:(NSString *)newSel
{
	[self.tableView reloadData];
}


- (void)dealloc {
	//[KeychainWrapper release];
	[reviewFrequencyList release];
    [super dealloc];
}

- (void)switchReviews:(id)sender
{
	BOOL oldValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"DownloadReviews"];
	
	UISwitch *mySwitch = (UISwitch *)sender;
	[[NSUserDefaults standardUserDefaults] setBool:mySwitch.on forKey:@"DownloadReviews"];
	
	if (oldValue == mySwitch.on) return;
	
	
	// show or hide the frequency cell
	if (mySwitch.on)
	{
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
		
	}
	else
	{
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationTop];
	}
}


/*
- (void)displayInfoUpdate:(NSNotification *) notification
{
	NSLog(@"displayInfoUpdate:");
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];

	
	
	if(notification)
	{
		[appDelegate.addresses release];
		appDelegate.addresses = [[notification object] copy];
		NSLog(@"addresses: %@", appDelegate.addresses);
	}
	if(appDelegate.addresses == nil)
	{
		return;
	}
	
	NSString *info;
	UInt16 port = [appDelegate.httpServer port];
	
	NSString *localIP = [appDelegate.addresses objectForKey:@"en0"];
	if (!localIP)
		info = @"Wifi: No Connection !\n";
	else
		info = [NSString stringWithFormat:@"http://iphone.local:%d		http://%@:%d\n", port, localIP, port];
	NSString *wwwIP = [appDelegate.addresses objectForKey:@"www"];
	if (wwwIP)
		info = [info stringByAppendingFormat:@"Web: %@:%d\n", wwwIP, port];
	else
		info = [info stringByAppendingString:@"Web: No Connection\n"];
	
	//displayInfo.text = info;
} */

- (void)serverStatusChanged:(NSNotification *) notification
{
	
	//[report_array insertObject:report atIndex:insertionIndex];
	
	NSIndexPath *tmpIndex = [NSIndexPath indexPathForRow:1 inSection:3];
	NSArray *insertIndexPaths = [NSArray arrayWithObjects:
								 tmpIndex,
								 nil];
	
	BOOL status = [(NSNumber *)[notification userInfo] boolValue];
	if (status==showAddress) return;
	
		if (status)
		{
			showAddress = YES;
			[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
			
		}
		else
		{
			showAddress = NO;
			[self.tableView deleteRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
			
		}
}


#pragma mark Actions
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex==0)
	{
		// hit ok, really do empty cache
		
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		[appDelegate emptyCache];
	}
}

#pragma mark EditAccount Delegate
- (void) deleteAccount:(Account *)deletedAccount
{
	AccountManager *am = [AccountManager sharedAccountManager];
	NSUInteger row = [am.accounts indexOfObject:deletedAccount];
	[am removeAccount:deletedAccount];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
	
	[self.tableView	deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
}

- (void) insertedAccount:(Account *)insertedAccount
{
	AccountManager *am = [AccountManager sharedAccountManager];
	NSUInteger row = [am.accounts indexOfObject:insertedAccount];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
	
	[self.tableView	insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
}


#pragma mark PinLock Delegate
- (void) didFinishSelectingNewPin:(NSString *)newPin
{
	[[NSUserDefaults standardUserDefaults] setObject:newPin forKey:@"PIN"];
	[self.navigationController dismissModalViewControllerAnimated:YES];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) didFinishRemovingPin
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PIN"];
	[self.navigationController dismissModalViewControllerAnimated:YES];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:3]] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark TableListSelector Delegate
- (void) didFinishSelectingFromTableListIndex:(NSInteger)index
{
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"ReviewFrequency"];
	[self.navigationController popViewControllerAnimated:YES];
}

@end

