//
//  ReportRootController.m
//  ASiST
//
//  Created by Oliver Drobnik on 17.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ReportRootController.h"
#import "ReportViewController.h"
#import "ASiSTAppDelegate.h"
#import "BirneConnect.h"
#import "Report.h"


@implementation ReportRootController

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
	
	report_icon = [UIImage imageNamed:@"Report_Icon.png"];
	report_icon_new = [UIImage imageNamed:@"Report_Icon_New.png"];

	newReportsByType = [[NSMutableDictionary alloc] init];

	// need to get starting values
	ASiSTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	[newReportsByType setObject:[NSNumber numberWithInt:[appDelegate.itts numberOfNewReportsOfType:0]] forKey:[NSNumber numberWithInt:0]];
    [newReportsByType setObject:[NSNumber numberWithInt:[appDelegate.itts numberOfNewReportsOfType:1]] forKey:[NSNumber numberWithInt:1]];

	NSLog(@"loaded %@", newReportsByType);

	// after loading we can get the badges updated via notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newReportNotification:) name:@"NewReportAdded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newReportRead:) name:@"NewReportRead" object:nil];
	
}



// new Reports cause update of badges
- (void)newReportNotification:(NSNotification *) notification
{
	
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		Report *report = [tmpDict objectForKey:@"Report"];
		NSNumber *typeKey = [NSNumber numberWithInt:report.reportType];
		NSNumber *theNum = [newReportsByType objectForKey:typeKey];
		if (!theNum)
		{
			theNum = [NSNumber numberWithInt:1];
			[newReportsByType setObject:theNum forKey:typeKey];
		}
		else
		{
			NSNumber *newNum = [NSNumber numberWithInt:[theNum intValue]+1];
			[newReportsByType setObject:newNum forKey:typeKey];
		}

		[self.tableView reloadData];  // to change icon where there are new reports
	} 
}

// new Reports cause update of badges
- (void)newReportRead:(NSNotification *) notification
{
	
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		Report *report = [tmpDict objectForKey:@"Report"];
		NSNumber *typeKey = [NSNumber numberWithInt:report.reportType];
		NSNumber *theNum = [newReportsByType objectForKey:typeKey];
		if (theNum)
		{
			NSNumber *newNum = [NSNumber numberWithInt:[theNum intValue]-1];
			[newReportsByType setObject:newNum forKey:typeKey];
		}
		
		[self.tableView reloadData];  // to change icon where there are new reports
	} 
}

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
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	switch (indexPath.row) 
	{
		case 0:
			cell.text = @"Days";
			break;
		case 1:
			cell.text = @"Weeks";
			break;
		default:
			break;
	}

	NSNumber *typeKey = [NSNumber numberWithInt:indexPath.row];
	NSNumber *theNum = [newReportsByType objectForKey:typeKey];
	
	if (theNum&&[theNum intValue]>0)
	{
		cell.image = report_icon_new;
	}
	else
	{
		cell.image = report_icon;
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	
	
	 ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	 // row = report_type_id
	 NSMutableArray *tmpArray = [[appDelegate.itts reportsByType] objectAtIndex:indexPath.row];
	 
	 NSSortDescriptor *dateDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"fromDate" ascending:NO] autorelease];
	 NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
	 NSArray *sortedArray = [tmpArray sortedArrayUsingDescriptors:sortDescriptors];
	
	ReportViewController *reportViewController = [[ReportViewController alloc] initWithReportArray:sortedArray reportType:indexPath.row style:UITableViewStylePlain];
	[self.navigationController pushViewController:reportViewController animated:YES];
	[reportViewController release];
}

// The accessory type is the image displayed on the far right of each table cell. In order for the delegate method
// tableView:accessoryButtonClickedForRowWithIndexPath: to be called, you must return the "Detail Disclosure Button" type.
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellAccessoryDisclosureIndicator;
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

	[newReportsByType release];
	[report_icon_new release];
	[report_icon release];
    [super dealloc];
}


@end

