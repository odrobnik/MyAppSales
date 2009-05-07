//
//  SettingsViewController.m
//  ASiST
//
//  Created by Oliver Drobnik on 14.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "EditableCell.h"
#import "SwitchCell.h"
#import "TextCell.h"
#import "YahooFinance.h"

// for the currency selection
#import "TableListView.h"

// to query currency list
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"

// for login data
#import "BirneConnect.h"
#import "KeychainWrapper.h"
#import <Security/Security.h>




@implementation SettingsViewController

@synthesize keychainWrapper;

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
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	self.keychainWrapper = appDelegate.keychainWrapper;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverStatusChanged:) name:@"ServerStatusChanged" object:nil];
	//[self.tableView setEditing:YES animated:NO];

	showAddress = NO;
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	
	
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

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
    return 3;
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
			return 2;
		case 1:  // reports
			return 2;
		case 2:  // web server
		{
			return showAddress?2:1;
		}
		case 3:  // test
			return 5;
		default:
			break;
	}
    return 0;
}


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

 

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	//ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];

	switch (indexPath.section) 
	{
		case 0:  // password
		{
			NSString *CellIdentifier = @"PasswordSection";
			
			EditableCell *cell = (EditableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) 
			{
				cell = [[[EditableCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
			}
			
			switch (indexPath.row) 
			{
				case 0:
				{
					cell.titleLabel.text = @"Username";
					//cell.textField.text = [appDelegate.itts username];
//					cell.textField.text = [keychainWrapper objectForKey:(id)kSecAttrAccount];
					[cell setSecKey:(id)kSecAttrAccount forKeychain:keychainWrapper];
					cell.textField.secureTextEntry = NO;
					cell.textField.placeholder = @"mail@example.com";
					cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
					break;
				}
				case 1:
				{
					cell.titleLabel.text = @"Password";
					//cell.textField.text = [appDelegate.itts password];
//					cell.textField.text = [keychainWrapper objectForKey:(id)kSecValueData];
					[cell setSecKey:(id)kSecValueData forKeychain:keychainWrapper];

					cell.textField.placeholder = @"Mandadory";
					cell.textField.secureTextEntry = YES;
					cell.textField.keyboardType = UIKeyboardTypeDefault;
					break;
				}
				default:
					break;
			}
			return cell;
		}
		case 1:   // general
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
			
		case 2:   // web server
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
			
		case 3:
		{
			NSString *CellIdentifier = @"testSection";
	
			TextCell *cell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) 
			{
				cell = [[[TextCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
			}
			
			cell.title.text = @"test";
			
			cell.value.text = @"test";
			return cell;		
			
		}
			
	}

	//NSLog([indexPath description]);
    return nil;
	}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section)
	{
		NSIndexPath *targetPath = [NSIndexPath indexPathForRow:0 inSection:0];
		EditableCell *targetCell = (EditableCell *)[self.tableView cellForRowAtIndexPath:targetPath];
		[targetCell hideKeyboard];
		targetPath = [NSIndexPath indexPathForRow:1 inSection:0];
		targetCell = (EditableCell *)[self.tableView cellForRowAtIndexPath:targetPath];
		[targetCell hideKeyboard];
	}
	
	
	if (indexPath.section == 1)
	{
		if (indexPath.row)
			return;
		
		// Navigation logic may go here. Create and push another view controller.
		TableListView *anotherViewController = [[TableListView alloc] initWithYahoo:[YahooFinance sharedInstance] style:UITableViewStylePlain];
		anotherViewController.title = @"Main Currency";
		[anotherViewController setSelectedItem:[[YahooFinance sharedInstance] mainCurrency]];
		[self.navigationController pushViewController:anotherViewController animated:YES];
		[anotherViewController release];
	}
}

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


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Login";
		case 1:
			return @"Reports";
		case 2:
			return @"Import/Export Server";
		default:
			break;
	}
	return nil;
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
	[KeychainWrapper release];
    [super dealloc];
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
	
	NSIndexPath *tmpIndex = [NSIndexPath indexPathForRow:1 inSection:2];
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

@end

