///
//  AccountTypeSelector.m
//  ASiST
//
//  Created by Oliver on 25.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "AccountTypeSelector.h"
#import "AccountManager.h"


@implementation AccountTypeSelector

@synthesize delegate;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
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

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 60.0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	
	
	switch (indexPath.row) {
		case 0:
		{
			cell.textLabel.text = @"iTunes Connect";
			cell.imageView.image = [UIImage imageNamed:@"apple_logo.png"];
			break;
		}
		case 1:
		{
			cell.textLabel.text = @"Notifications";
			cell.imageView.image = [UIImage imageNamed:@"notifications_logo.png"];
			break;
		}
		case 2:
		{
			cell.textLabel.text = @"Applyzer";
			break;
		}
		default:
			break;
	}

	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.textLabel.font = [UIFont systemFontOfSize:20.0];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	EditAccountController *controller = [[[EditAccountController alloc] initWithAccount:nil] autorelease];
	controller.title = @"Add Account...";
	controller.delegate = delegate;
	
	switch (indexPath.row) 
	{
		case 0:
		{
			controller.typeForNewAccount = AccountTypeITC;
			
			break;
		}
		case 1:
		{
			controller.typeForNewAccount = AccountTypeNotifications;
			
			NSArray *previousAccounts = [[AccountManager sharedAccountManager] accountsOfType:[GenericAccount stringForAccountType:AccountTypeNotifications]];
			
			if ([previousAccounts count])
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Account Already Exists" message:@"Only one Notifications account can be configured." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
				[alert show];
				[alert release];
				
				return;
			}
			
			break;
		}
		case 2:
		{
			controller.typeForNewAccount = AccountTypeApplyzer;
			
			break;
		}
		default:
			break;
	}
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
	navController.navigationBar.barStyle = UIBarStyleBlack;
	
	[self presentModalViewController:navController animated:YES];
	[navController release]; 
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
    [super dealloc];
}


@end

