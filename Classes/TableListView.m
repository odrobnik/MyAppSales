//
//  TableListView.m
//  ASiST
//
//  Created by Oliver Drobnik on 15.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "TableListView.h"
#import "TextCell.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
#import "iTunesConnect.h"
#import "SettingsViewController.h"


@implementation TableListView

@synthesize myYahoo, selectedIndex;


- (id)initWithYahoo:(YahooFinance *)yahoo style:(UITableViewStyle)style
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) 
	{
		self.myYahoo = yahoo;
    }
    return self;
}


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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];

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
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [myYahoo.allCurrencies count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    TextCell *cell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[TextCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	
	
	NSArray *names = [myYahoo.nameIndex allKeys];
	NSArray *sortedNames = [names sortedArrayUsingSelector:@selector(compare:)];
	NSString *name = [sortedNames objectAtIndex:indexPath.row];
	NSString *currency = [myYahoo.nameIndex objectForKey:name];
	
	cell.title.text = name;
	cell.CELL_IMAGE = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", currency]];

	if (indexPath.row == selectedIndex)
	{
		cell.accessoryType=UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType=UITableViewCellAccessoryNone;
	}
	
    return cell;
}

/*
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == selectedIndex)
	{
		return UITableViewCellAccessoryCheckmark;
	}
	else
	{
		return UITableViewCellAccessoryNone;
	}
} */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	
	selectedIndex = indexPath.row;
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self.tableView reloadData];
	
	NSArray *names = [myYahoo.nameIndex allKeys];
	NSArray *sortedNames = [names sortedArrayUsingSelector:@selector(compare:)];
	NSString *name = [sortedNames objectAtIndex:indexPath.row];
	NSString *currency = [myYahoo.nameIndex objectForKey:name];
	
	[[YahooFinance sharedInstance] setMainCurrency:currency];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) setSelectedItem:(NSString *)aText
{
	NSArray *names = [myYahoo.nameIndex allKeys];
	NSArray *sortedNames = [names sortedArrayUsingSelector:@selector(compare:)];
	
	NSEnumerator *enu = [sortedNames objectEnumerator];
	NSString *name;
	
	int idx = 0;
	while (name = [enu nextObject]) 
	{
		NSString *key = [myYahoo.nameIndex objectForKey:name];
		
		if ([key isEqualToString:aText])
		{
			
			selectedIndex = idx;
			return;
		}
		
		idx++;
	}
	
	
	
	
/*	
	
	NSString *name = [sortedNames objectAtIndex:indexPath.row];
	
	
	
	
	NSString *currency = [myYahoo.nameIndex objectForKey:name];
	
	
	NSArray *keys = [myYahoo.allCurrencies allKeys];
	int idx = [keys indexOfObject:aText];
	selectedIndex = idx;
	
	
	NSString *currency = [keys objectAtIndex:indexPath.row];
	NSDictionary *item = [myYahoo.allCurrencies objectForKey:currency];
	
	
	NSEnumerator *enu = [myList objectEnumerator];
	NSDictionary *oneEntry;
	int idx=0;
	
	while (oneEntry = [enu nextObject]) 
	{
		NSString *code = [oneEntry objectForKey:@"countryCode"];
		if ([aText isEqualToString:code])
		{
			selectedIndex = idx;
			return;
		}
		
		idx++;
	}
 
 */
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
	[myYahoo release];
    [super dealloc];
}


@end

