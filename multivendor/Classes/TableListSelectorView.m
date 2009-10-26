//
//  TableListSelectorView.m
//  ASiST
//
//  Created by Oliver on 15.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "TableListSelectorView.h"


@implementation TableListSelectorView

@synthesize selectedIndex, delegate;


- (id) initWithList:(NSArray *)list
{
    if (self = [super initWithStyle:UITableViewStylePlain]) 
	{
		myList = [list retain];
   
	}
    return self;
}

- (id) initWithDictionary:(NSDictionary *)dict
{
    if (self = [super initWithStyle:UITableViewStylePlain]) 
	{
		// the list are the keys of the dictionary
		myList = [[dict keysSortedByValueUsingSelector:@selector(compare:)] retain];

		myDictionary = [dict retain]; // for looking up the long text
	}
    return self;
}


- (void)dealloc 
{
	[myDictionary release];
	[myList release];
    [super dealloc];
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
    return [myList count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	if (myDictionary)
	{
		cell.textLabel.text = [[myDictionary objectForKey:[myList objectAtIndex:indexPath.row]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	else
	{
		cell.textLabel.text = [myList objectAtIndex:indexPath.row];
	}

	
	if (indexPath.row == selectedIndex)
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (selectedIndex>=0)
	{
		UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
		oldCell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	selectedIndex = indexPath.row;

	UITableViewCell *newCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
	newCell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	if (myDictionary)
	{
		if (delegate && [delegate respondsToSelector:@selector(didFinishSelectingFromTableKey:)])
		{
			[delegate didFinishSelectingFromTableKey:[myList objectAtIndex:selectedIndex]];
		}
	}
	else if (delegate && [delegate respondsToSelector:@selector(didFinishSelectingFromTableListIndex:)])
	{
		[delegate didFinishSelectingFromTableListIndex:selectedIndex];
	} 
	
	
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


- (NSString *) selectedKey
{
	return [myList objectAtIndex:selectedIndex];
}

- (void) setSelectedKey:(NSString *)newKey
{
	NSUInteger idx = 0;
	for (NSString *oneKey in myList)
	{
		if ([oneKey isEqualToString:newKey])
		{
			selectedIndex = idx;
			return;
		}
		idx++;
	}
}

@end

