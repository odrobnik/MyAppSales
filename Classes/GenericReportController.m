//
//  GenericReportController.m
//  ASiST
//
//  Created by Oliver Drobnik on 29.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GenericReportController.h"
#import "Report.h"
#import "Sale.h"
#import "Country.h"
#import "App.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
#import "BirneConnect.h"
#import "CountrySummary.h"
#import "ReportCell.h"

@implementation GenericReportController

@synthesize filteredApp;

- (id) initWithReport:(Report *)aReport
{
	if (self = [super initWithStyle:UITableViewStylePlain]) {
		report = aReport;
		[report hydrate];
		self.title = [aReport listDescription];
		sumImage = [UIImage imageNamed:@"Sum.png"];
		filteredApp = nil;

    }
    return self;
}


		

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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (filteredApp)
	{
		return 1;
	}
	else
	{
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		return [appDelegate.itts.apps count]+1;   // one extra section for totals over all apps
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	
	// if we want to see only one app, then ...
	if (filteredApp)
	{
		return nil;
	}
	
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	// section 0 = totals
	if (section)
	{
		
		NSNumber *app_id = [[appDelegate.itts appKeysSortedBySales] objectAtIndex:section-1];  // minus one because of totals section
		App *tmpApp = [appDelegate.itts.apps objectForKey:app_id];

		if (tmpApp)
		{
			return tmpApp.title;
		}
		else
		{
			return @"Invalid";
		}
	}
	else
	{
		return @"Total Summary";

	}
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	
	// we filter for one app
	if (filteredApp)
	{
		NSNumber *app_id = [NSNumber numberWithInt:filteredApp.apple_identifier];  // minus one because of totals section
		
		NSArray *thisArray = [report.summariesByApp objectForKey:app_id];
		return [thisArray count]+1+1;  // add one for app summary plus one for header
	}
	
	// we don't filter
	if (section)
	{
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		NSNumber *app_id = [[appDelegate.itts appKeysSortedBySales] objectAtIndex:section-1];  // minus one because of totals section

		NSArray *thisArray = [report.summariesByApp objectForKey:app_id];
		return [thisArray count]+1+1;  // add one for app summary and one header
		
	}
	else
	{
		return 2;   // one row in totals section plus 1 header
	}
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath.row)
	{
		return 20.0;
	}
	else
	{
		return 50.0;
	}
}


// Customize the appearance of table view cells.

- (ReportCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
    static NSString *CellIdentifier;
	
	if (!indexPath.row)
	{
		CellIdentifier =  @"HeaderCell";
	}
	else
	{
		CellIdentifier =  @"Cell";
	}
    
   ReportCell *cell = (ReportCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ReportCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];

	NSNumber *app_id;
	
	if (filteredApp)
	{
		app_id = [NSNumber numberWithInt:filteredApp.apple_identifier];
	}
	else
	{
	if (!indexPath.section)   // extra section for totals over all apps
	{
		if (!indexPath.row)
		{
			// headers
			cell.unitsSoldLabel.text = @"Units";
			cell.unitsSoldLabel.font = [UIFont systemFontOfSize:8.0];
			cell.unitsSoldLabel.textAlignment = UITextAlignmentCenter;
			
			cell.unitsRefundedLabel.text = @"Refunds";
			cell.unitsRefundedLabel.font = [UIFont systemFontOfSize:8.0];
			cell.unitsRefundedLabel.textAlignment = UITextAlignmentCenter;
			
			cell.unitsUpdatedLabel.text = @"Updates";
			cell.unitsUpdatedLabel.font = [UIFont systemFontOfSize:8.0];
			cell.unitsUpdatedLabel.textAlignment = UITextAlignmentCenter;
			
			
			cell.royaltyEarnedLabel.text = @"Royalties";
			cell.royaltyEarnedLabel.font = [UIFont systemFontOfSize:8.0];
			cell.royaltyEarnedLabel.textAlignment = UITextAlignmentRight;
		}
		else
		{
			cell.image = sumImage;
			cell.countryCodeLabel.text = @"";
			
			cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", report.sumUnitsSold];
			cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", report.sumUnitsUpdated];
			NSInteger refunds = report.sumUnitsRefunded;
			if (refunds)
			{
				cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", refunds];
			}
			else
			{
				cell.unitsRefundedLabel.text = @"";
			}
			
			
			YahooFinance *myYahoo = appDelegate.itts.myYahoo;
			double convertedRoyalties = [myYahoo convertToCurrency:appDelegate.itts.myYahoo.mainCurrency amount:report.sumRoyaltiesEarned fromCurrency:@"EUR"];
			cell.royaltyEarnedLabel.text = [appDelegate.itts.myYahoo formatAsCurrency:appDelegate.itts.myYahoo.mainCurrency amount:convertedRoyalties];
			
			
			//cell.contentView.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:0.9];
		}
		return cell;
	}

	app_id  = [[appDelegate.itts appKeysSortedBySales] objectAtIndex:indexPath.section-1];  // minus one because of totals section
	}	
	
	if (indexPath.row==1)
	{ // summary
		
		cell.image = sumImage;
		cell.countryCodeLabel.text = @"";
		cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", [report sumUnitsForAppId:app_id transactionType:TransactionTypeSale]];
		cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", [report sumUnitsForAppId:app_id transactionType:TransactionTypeFreeUpdate]];
		NSInteger refunds = [report  sumRefundsForAppId:app_id];
		if (refunds)
		{
			cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", refunds];
		}
		else
		{
			cell.unitsRefundedLabel.text = @"";
		}
		
		YahooFinance *myYahoo = appDelegate.itts.myYahoo;
		double convertedRoyalties = [myYahoo convertToCurrency:appDelegate.itts.myYahoo.mainCurrency amount:[report  sumRoyaltiesForAppId:app_id transactionType:TransactionTypeSale] fromCurrency:@"EUR"];
		cell.royaltyEarnedLabel.text = [appDelegate.itts.myYahoo formatAsCurrency:appDelegate.itts.myYahoo.mainCurrency amount:convertedRoyalties];
		//cell.contentView.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:0.9];
		
		return cell;
	}
	else if (indexPath.row==0)
	{
		// headers
		cell.unitsSoldLabel.text = @"Units";
		cell.unitsSoldLabel.font = [UIFont systemFontOfSize:8.0];
		cell.unitsSoldLabel.textAlignment = UITextAlignmentCenter;
		
		cell.unitsRefundedLabel.text = @"Refunds";
		cell.unitsRefundedLabel.font = [UIFont systemFontOfSize:8.0];
		cell.unitsRefundedLabel.textAlignment = UITextAlignmentCenter;
		
		cell.unitsUpdatedLabel.text = @"Updates";
		cell.unitsUpdatedLabel.font = [UIFont systemFontOfSize:8.0];
		cell.unitsUpdatedLabel.textAlignment = UITextAlignmentCenter;
		
		
		cell.royaltyEarnedLabel.text = @"Royalties";
		cell.royaltyEarnedLabel.font = [UIFont systemFontOfSize:8.0];
		cell.royaltyEarnedLabel.textAlignment = UITextAlignmentRight;
		
		return cell;
	}

	//cell.contentView.backgroundColor = [UIColor whiteColor];

	NSMutableDictionary *thisDict = [report.summariesByApp objectForKey:app_id];
	NSArray *dictKeys = [thisDict keysSortedByValueUsingSelector:@selector(compareBySales:)];  // all countries
	CountrySummary *tmpSummary = [thisDict objectForKey:[dictKeys objectAtIndex:indexPath.row-2]];
	cell.image = tmpSummary.country.iconImage;
	cell.countryCodeLabel.text = tmpSummary.country.iso3;

	
	if (tmpSummary.sumSales>0)
	{
		cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", tmpSummary.sumSales];

		
		if (appDelegate.convertSalesToMainCurrency)
		{ 
			YahooFinance *myYahoo = appDelegate.itts.myYahoo;
			double convertedRoyalties = [myYahoo convertToCurrency:appDelegate.itts.myYahoo.mainCurrency amount:tmpSummary.sumRoyalites fromCurrency:tmpSummary.royaltyCurrency];
			
			cell.royaltyEarnedLabel.text = [appDelegate.itts.myYahoo formatAsCurrency:appDelegate.itts.myYahoo.mainCurrency amount:convertedRoyalties];
		}
		else
		{
			cell.royaltyEarnedLabel.text = [appDelegate.itts.myYahoo formatAsCurrency:tmpSummary.royaltyCurrency amount:tmpSummary.sumRoyalites];
		}
	}
	else
	{
		cell.unitsSoldLabel.text = @"";
		cell.royaltyEarnedLabel.text = @"";  // because of reuse we need to empty cells
	}
	
	if (tmpSummary.sumUpdates>0)
	{
		cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", tmpSummary.sumUpdates];
	}
	else
	{
		cell.unitsUpdatedLabel.text = @"";
	}
	
	if (tmpSummary.sumRefunds)
	{
		cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", tmpSummary.sumRefunds];
	}	
	else
	{
		cell.unitsRefundedLabel.text = @"";
	}
	
	
	
	

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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




- (void)dealloc {
	[filteredApp release];
    [super dealloc];
}


@end

