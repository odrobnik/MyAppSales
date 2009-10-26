//
//  AppViewController.m
//  ASiST
//
//  Created by Oliver Drobnik on 21.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "AppViewController.h"
#import "ASiSTAppDelegate.h"
#import "App.h"
#import "Sale.h"
#import "Report.h"
#import "AppCell.h"

#import "AppDetailViewController.h"

@implementation AppViewController

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/


- (void)viewDidLoad {
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newAppNotification:) name:@"NewAppAdded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTotalsUpdated:) name:@"AppTotalsUpdated" object:nil];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
}

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
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Notifications
- (void)newAppNotification:(NSNotification *) notification
{
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];

		NSInteger insertionIndex = [[tmpDict objectForKey:@"InsertionIndex"] intValue];
			
		NSIndexPath *tmpIndex = [NSIndexPath indexPathForRow:insertionIndex inSection:0];
		NSArray *insertIndexPaths = [NSArray arrayWithObjects:
										 tmpIndex,
										 nil];
		
		[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];

	} 
}

- (void)appTotalsUpdated:(NSNotification *) notification
{
	// need to update entire table to reflect new totals
	[self.tableView reloadData];
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// The accessory type is the image displayed on the far right of each table cell. In order for the delegate method
// tableView:accessoryButtonClickedForRowWithIndexPath: to be called, you must return the "Detail Disclosure Button" type.
/*
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellAccessoryNone;
}
*/

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [DB countOfApps];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    AppCell *cell = (AppCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[AppCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	NSArray *sortedApps = [DB appsSortedBySales];
	cell.app = [sortedApps objectAtIndex:indexPath.row];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row%2)
	{
		// light
		cell.backgroundColor=[UIColor colorWithRed:173.0/256.0 green:173.0/256.0 blue:176.0/256.0 alpha:1.0];
	}
	else
	{
		// dark
		cell.backgroundColor=[UIColor colorWithRed:152.0/256.0 green:152.0/256.0 blue:156.0/256.0 alpha:1.0];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSArray *sortedApps = [DB appsSortedBySales];
	App *rowApp = [sortedApps objectAtIndex:indexPath.row];
	
    // Navigation logic may go here. Create and push another view controller.
	AppDetailViewController *anotherViewController = [[AppDetailViewController alloc] initForApp:rowApp];
	[self.navigationController pushViewController:anotherViewController animated:YES];
	 [anotherViewController release];
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
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}


@end

