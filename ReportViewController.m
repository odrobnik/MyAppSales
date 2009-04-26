//
//  ReportViewController.m
//  ASiST
//
//  Created by Oliver Drobnik on 26.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ReportViewController.h"
#import "ASiSTAppDelegate.h"
#import "BirneConnect.h"
#import "Report.h"
//#import "GenericReportController.h"
#import "ReportAppsController.h"



@implementation ReportViewController


@synthesize report_array, tabBarItem;


- (id)initWithReportArray:(NSArray *)array reportType:(ReportType)type style:(UITableViewStyle)style 
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
		self.report_array = [NSMutableArray arrayWithArray:array];  // make it mutable for insertions
		report_type = type;
		
		switch (report_type) {
			case ReportTypeDay:
				self.title = @"Days";
				break;
			case ReportTypeWeek:
				self.title = @"Weeks";
				break;
			default:
				break;
		}

		self.tabBarItem = self.parentViewController.tabBarItem;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newReportNotification:) name:@"NewReportAdded" object:nil];


    }
    return self;
}


// new Reports cause insertion animation
- (void)newReportNotification:(NSNotification *) notification
{
	
	
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		Report *report = [tmpDict objectForKey:@"Report"];

		if (report.reportType == report_type)
		{	
			// this concerns use, it's the type we are showing
				// we have only one section here, so we set it to 0
			NSInteger insertionIndex = [[tmpDict objectForKey:@"InsertionIndex"] intValue];
			
			[report_array insertObject:report atIndex:insertionIndex];
		
			NSIndexPath *tmpIndex = [NSIndexPath indexPathForRow:insertionIndex inSection:0];
			NSArray *insertIndexPaths = [NSArray arrayWithObjects:
									 tmpIndex,
									 nil];
		
			[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];

		}
	} 
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	report_icon = [UIImage imageNamed:@"Report_Icon.png"];
	report_icon_new = [UIImage imageNamed:@"Report_Icon_New.png"];

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
   // return 2;
	return 1;   // only one report type here
}

// The accessory type is the image displayed on the far right of each table cell. In order for the delegate method
// tableView:accessoryButtonClickedForRowWithIndexPath: to be called, you must return the "Detail Disclosure Button" type.
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellAccessoryDisclosureIndicator;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
/*
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	// section = report_type_id
	NSMutableArray *tmpArray = [[appDelegate.itts reportsByType] objectAtIndex:section];
	
	return [tmpArray count];
*/
	return [report_array count];
 
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	Report *tmpReport = [report_array objectAtIndex:indexPath.row];
	
	cell.text = [tmpReport listDescription];
	
	if (tmpReport.isNew)
	{
		cell.image = report_icon_new;
	}
	else
	{
		cell.image = report_icon;
	}

    return cell;
}


/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
		switch (section) {
			case ReportTypeDay:
				return @"Days";
				break;
			case ReportTypeWeek:
				return @"Weeks";
				break;
			default:
				break;
		}
	return nil;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	Report *tmpReport = [report_array objectAtIndex:indexPath.row];
	
    
	// Navigation logic may go here. Create and push another view controller.

	/* old style
	GenericReportController *genericReportController = [[GenericReportController alloc] initWithReport:tmpReport];
	[self.navigationController pushViewController:genericReportController animated:YES];
	[genericReportController release];
	 */

	ReportAppsController *reportAppsController = [[ReportAppsController alloc] initWithReport:tmpReport];
	[self.navigationController pushViewController:reportAppsController animated:YES];
	[reportAppsController release];

	// if this was a new report, now it ain't any longer
	if (tmpReport.isNew)
	{
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate.itts newReportRead:tmpReport];
		[self.tableView reloadData];  // only way to remove the red stars
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
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[tabBarItem release];
    [super dealloc];
}


@end

