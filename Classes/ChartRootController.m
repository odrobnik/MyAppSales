//
//  ChartRootController.m
//  ASiST
//
//  Created by Oliver Drobnik on 20.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "ChartRootController.h"
#import "ChartViewController.h"
#import "Query.h"

#import "ASiSTAppDelegate.h"
#import "BirneConnect.h"


@implementation ChartRootController

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
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
		switch (section) {
			case 0:
				return @"Paid Apps";
				break;
			case 1:
				return @"Free Apps";
			default:
				break;
		}
	return nil;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return 6;
		case 1:
			return 2;
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...

	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
				{
					cell.text = @"Daily Sales";
					break;
				}
				case 1:
				{
					cell.text = @"Weekly Sales";
					break;
				}
				case 2:
				{
					cell.text = @"Daily Sales Total";
					break;
				}
				case 3:
				{
					cell.text = @"Weekly Sales Total";
					break;
				}
				case 4:
				{
					cell.text = @"Daily Sold Downloads";
					break;
				}
				case 5:
				{
					cell.text = @"Weekly Sold Downloads";
					break;
				}
				default:
					break;
			}
			break;
		case 1:
			switch (indexPath.row) {
				case 0:
				{
					cell.text = @"Daily Downloads";
					break;
				}
				case 1:
				{
					cell.text = @"Weekly Downloads";
					break;
				}
				default:
					break;
			}
			break;
		default:
			break;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.image = [UIImage imageNamed:@"Graphique-32.png"];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	Query *myQuery = [[Query alloc] initWithDatabase:[appDelegate.itts database]];
	
	NSDictionary *tmpData;
	NSString *reportTitle;
	NSString *columnToShow;
	
	switch (indexPath.section) {
		case 0:
		{
			columnToShow = @"Sum";
			switch (indexPath.row) 
			{
				case 0:
					tmpData = [myQuery chartDataForReportType:ReportTypeDay ShowFree:NO Axis:@"Sum" Itts:appDelegate.itts];
					reportTitle = @"Daily Sales";
					break;
				case 1:
					tmpData = [myQuery chartDataForReportType:ReportTypeWeek ShowFree:NO Axis:@"Sum" Itts:appDelegate.itts];
					reportTitle = @"Weekly Sales";
					break;
				case 2:
					tmpData = [myQuery chartDataForReportType:ReportTypeDay ShowFree:NO Axis:@"Sum" Itts:appDelegate.itts];
					tmpData = [myQuery stackAndTotalReport:tmpData];
					reportTitle = @"Daily Sales Total";
					break;
				case 3:
					tmpData = [myQuery chartDataForReportType:ReportTypeWeek ShowFree:NO Axis:@"Sum" Itts:appDelegate.itts];
					tmpData = [myQuery stackAndTotalReport:tmpData];
					reportTitle = @"Weekly Sales Total";
					break;
				case 4:
					tmpData = [myQuery chartDataForReportType:ReportTypeDay ShowFree:NO Axis:@"Units" Itts:appDelegate.itts];
					reportTitle = @"Daily Sold Downloads";
					break;
				case 5:
					tmpData = [myQuery chartDataForReportType:ReportTypeWeek ShowFree:NO Axis:@"Units" Itts:appDelegate.itts];
					reportTitle = @"Weekly Sold Downloads";
					break;
				default:
					break;
			}
			break;
		}
		case 1:
		{
			columnToShow = @"Units";
			switch (indexPath.row) {
				case 0:
					tmpData = [myQuery chartDataForReportType:ReportTypeDay ShowFree:YES Axis:@"Units" Itts:appDelegate.itts];
					reportTitle = @"Daily Downloads";
					break;
				case 1:
					tmpData = [myQuery chartDataForReportType:ReportTypeWeek ShowFree:YES Axis:@"Units" Itts:appDelegate.itts];
					reportTitle = @"Weekly Downloads";
					break;
				default:
					break;
			}
		}
		default:
			break;
	}
	
	[myQuery release];

	
	NSArray *colLabels = [tmpData objectForKey:@"Columns"];
	
	if ([colLabels count]>0)
	{	
		//if ([colLabels count]>1)
		{
			ChartViewController *chartViewController = (ChartViewController *)[[ChartViewController alloc] initWithChartData:tmpData]; 
			chartViewController.title = reportTitle;
	
			[self.navigationController pushViewController:chartViewController animated:YES];
			[chartViewController release];
		}
	/*	else
		{
			
			
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:reportTitle message:@"This chart needs more than one report to be drawn correctly." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
			[alert release];
		} */
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:reportTitle message:@"There is no data to show on this report." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
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

