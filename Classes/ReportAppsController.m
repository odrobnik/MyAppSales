//
//  ReportAppsController.m
//  ASiST
//
//  Created by Oliver Drobnik on 02.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ReportAppsController.h"
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

@implementation ReportAppsController

@synthesize report;

- (id) initWithReport:(Report *)aReport
{
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		report = aReport;
		[report hydrate];
		self.title = [aReport listDescription];
		sumImage = [UIImage imageNamed:@"Sum.png"];
		
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

// The accessory type is the image displayed on the far right of each table cell. In order for the delegate method
// tableView:accessoryButtonClickedForRowWithIndexPath: to be called, you must return the "Detail Disclosure Button" type.
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath 
{
	if (!indexPath.row)
	{
		return UITableViewCellAccessoryNone;
	}
	else
	{
		return UITableViewCellAccessoryDisclosureIndicator;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	return [appDelegate.itts.apps count]+1;   // one extra section for totals over all apps
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
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
	switch (section) {
		case 0:
			return 2;   // summary also has explanation cell
			break;
		default:
			return 2;
			break;
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
		return cell;
	}
	
    // Set up the cell...
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if (!indexPath.section)   // extra section for totals over all apps
	{
		if (indexPath.row)
		{
			cell.image = sumImage;
			
			cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", report.sumUnitsSold];
			cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", report.sumUnitsUpdated];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			NSInteger refunds = report.sumUnitsRefunded;
			if (refunds)
			{
				cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", refunds];
			}
			else
			{
				cell.unitsRefundedLabel.text = @"";
			}
			
			cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report sumRoyaltiesEarned]];
		}

		
		//cell.contentView.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:0.9];
		return cell;
	}
	
	NSNumber *app_id  = [[appDelegate.itts appKeysSortedBySales] objectAtIndex:indexPath.section-1];  // minus one because of totals section
	App *rowApp = [[appDelegate.itts appsSortedBySales] objectAtIndex:indexPath.section-1];  // minus one because of totals section
	
	
	NSMutableDictionary *thisDict = [report.summariesByApp objectForKey:app_id];

	cell.selectionStyle = UITableViewCellSelectionStyleBlue;

	
	if (indexPath.row==1)
	{ // summary
		
		//cell.image = sumImage;
		cell.image = rowApp.iconImageNano;
		
		//NSNumber *app_id = [keys objectAtIndex:indexPath.section-1]; 
		cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", [report  sumUnitsForAppId:app_id transactionType:TransactionTypeSale]];
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
		
		double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report  sumRoyaltiesForAppId:app_id transactionType:TransactionTypeSale] fromCurrency:@"EUR"];
		cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
		
		return cell;
	}
	
	NSArray *dictKeys = [thisDict keysSortedByValueUsingSelector:@selector(compareBySales:)];  // all countries
	CountrySummary *tmpSummary = [thisDict objectForKey:[dictKeys objectAtIndex:indexPath.row-1]];
	
	cell.image = tmpSummary.country.iconImage;
	
	
	if (tmpSummary.sumSales>0)
	{
		cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", tmpSummary.sumSales];
		
		
		if (appDelegate.convertSalesToMainCurrency)
		{ 
			double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:tmpSummary.sumRoyalites fromCurrency:tmpSummary.royaltyCurrency];
			
			cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
		}
		else
		{
			cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:tmpSummary.royaltyCurrency amount:tmpSummary.sumRoyalites];
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
	
	
	//Sale *tmpSale = [thisArray objectAtIndex:indexPath.row];
	//cell.image = tmpSale.country.iconImage;
	
	//NSLog( [NSString stringWithFormat:@"%@ s: %d = %.2f %@, u: %d, r: %d",  tmpSummary.country.iso3,tmpSummary.sumSales, tmpSummary.sumRoyalites, tmpSummary.royaltyCurrency, tmpSummary.sumUpdates, tmpSummary.sumRefunds]);
	//NSLog(@"ok");
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (!indexPath.row) return;
	
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];

	GenericReportController *genericReportController = [[GenericReportController alloc] initWithReport:self.report];

	switch (indexPath.section) {
		case 0:
		{
			genericReportController.title = @"All Apps";
			break;
		}
		default:
		{
			App *app =  [[appDelegate.itts appsSortedBySales] objectAtIndex:indexPath.section-1];
			genericReportController.title = app.title;
			genericReportController.filteredApp = app;
			break;
		}
	}
	[self.navigationController pushViewController:genericReportController animated:YES];
	[genericReportController release];
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

