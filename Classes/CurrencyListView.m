//
//  TableListView.m
//  ASiST
//
//  Created by Oliver Drobnik on 15.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "CurrencyListView.h"
#import "TextCell.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
#import "SettingsViewController.h"


@implementation CurrencyListView

@synthesize myYahoo, selectedIndex;


- (id)initWithYahoo:(YahooFinance *)yahoo style:(UITableViewStyle)style
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style]))
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



- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
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
}

- (void)dealloc 
{
	[myYahoo release];
    [super dealloc];
}


@end

