//
//  ReportAppsController.m
//  ASiST
//
//  Created by Oliver Drobnik on 02.02.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "ReportAppsController.h"
#import "GenericReportController.h"
#import "Report.h"
#import "Sale.h"
#import "Country.h"
#import "App.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
#import "CountrySummary.h"
#import "ReportCell.h"

@implementation ReportAppsController

@synthesize report;

- (void) setReport:(Report *)activeReport
{
	report = activeReport;
	
	if (activeReport.isNew)
	{
		[DB newReportRead:activeReport];
	}

	[report hydrate];

	if (report.reportType == ReportTypeFinancial)
	{
		self.title = [report listDescriptionShorter:YES];
	}
	else
	{
		self.title = [report listDescriptionShorter:YES];
	}

	[self.tableView reloadData];
}


- (id) initWithReport:(Report *)aReport
{
	if (self = [super initWithStyle:UITableViewStyleGrouped]) 
	{
		[self setReport:aReport];

		sumImage = [UIImage imageNamed:@"Sum.png"];
		
		segmentedControl = [[UISegmentedControl alloc] initWithItems:
							[NSArray arrayWithObjects:
							 [UIImage imageNamed:@"up.png"],
							 [UIImage imageNamed:@"down.png"],
							 nil]];
		[segmentedControl addTarget:self action:@selector(upDownPushed:) forControlEvents:UIControlEventValueChanged];
		segmentedControl.frame = CGRectMake(0, 0, 90, 30);
		segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		segmentedControl.momentary = YES;
		
		UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
		
		self.navigationItem.rightBarButtonItem = segmentBarItem;
		[segmentBarItem release];
		
		sortedApps = [[DB appsSortedBySalesWithGrouping:report.appGrouping] retain];
    }
    return self;
}

- (void)dealloc 
{
	[sortedApps release];
	[segmentedControl release];
    [super dealloc];
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

/*
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
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return [DB countOfApps] + 1; // one extra section for totals over all apps
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// section 0 = totals
	if (section)
	{
		App *tmpApp = [sortedApps objectAtIndex:section - 1];  // minus one because of totals section
		
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
		{
			App* sectionApp = [sortedApps objectAtIndex:section-1];
			
			if ([sectionApp inAppPurchases])
			{
				return 4;  // header + sum + app + iap
			}
			else
			{
				return 2;  // header + app
			}
			
			break;
		}
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
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
		
		cell.accessoryType = UITableViewCellAccessoryNone;
		return cell;
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    // Set up the cell...
	//ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if (!indexPath.section)   // extra section for totals over all apps
	{
		if (indexPath.row)
		{
			cell.CELL_IMAGE = sumImage;
			
			NSInteger units = [report sumUnitsForProduct:nil transactionType:TransactionTypeSale] +
								[report sumUnitsForProduct:nil transactionType:TransactionTypeIAP];			
			
			double royalties = [report sumRoyaltiesForProduct:nil transactionType:TransactionTypeSale] +
								[report sumRoyaltiesForProduct:nil transactionType:TransactionTypeIAP];

			
			cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", units];
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
			
			double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:royalties fromCurrency:@"EUR"];
			cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
		}

		
		//cell.contentView.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:0.9];
		return cell;
	}
	
	
	App *rowApp = [sortedApps objectAtIndex:indexPath.section-1];  // minus one because of totals section
	
	
	//NSMutableDictionary *thisDict = [report.summariesByApp objectForKey:[NSNumber numberWithInt:rowApp.apple_identifier]];

	cell.selectionStyle = UITableViewCellSelectionStyleBlue;


	if ([rowApp inAppPurchases])
	{
		switch (indexPath.row) 
		{
			case 0:
				// header
				break;
			case 1:
			{
				// sum IAP + APP
				cell.CELL_IMAGE = sumImage;
				
				NSInteger appUnits = [report sumUnitsForProduct:rowApp transactionType:TransactionTypeSale];
				NSInteger appUpdates = [report sumUnitsForProduct:rowApp transactionType:TransactionTypeFreeUpdate];
				double appRoyalites = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report sumRoyaltiesForProduct:rowApp transactionType:TransactionTypeSale] fromCurrency:@"EUR"];
				double iapRoyalites = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report sumRoyaltiesForInAppPurchasesOfApp:rowApp] fromCurrency:@"EUR"];
				
				NSInteger iapUnits = [report sumUnitsForInAppPurchasesOfApp:rowApp];

				cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", appUnits + iapUnits];
				cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", appUpdates];

				cell.unitsRefundedLabel.text = nil;
				
				
				//double salesRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report sumRoyaltiesEarned] fromCurrency:@"EUR"];
				//cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];

				
				cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:appRoyalites + iapRoyalites];
				break;
			}
			case 2:
			{
				// APP
				
				// summary for one app
				cell.CELL_IMAGE = rowApp.iconImageNano;
				
				cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", [report sumUnitsForProduct:rowApp transactionType:TransactionTypeSale]];
				cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", [report sumUnitsForProduct:rowApp transactionType:TransactionTypeFreeUpdate]];
				NSInteger refunds = [report  sumRefundsForAppId:rowApp.apple_identifier];
				if (refunds)
				{
					cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", refunds];
				}
				else
				{
					cell.unitsRefundedLabel.text = @"";
				}
				
				double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report sumRoyaltiesForProduct:rowApp transactionType:TransactionTypeSale] fromCurrency:@"EUR"];
				cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
				
				break;
			}
			case 3:
			{
				// IAP
				
				cell.CELL_IMAGE = [UIImage imageNamed:@"IAP_nano.png"];
				
				cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", [report sumUnitsForInAppPurchasesOfApp:rowApp]];
				cell.unitsUpdatedLabel.text = nil;
				cell.unitsRefundedLabel.text = nil;
				
				double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report  sumRoyaltiesForInAppPurchasesOfApp:rowApp] fromCurrency:@"EUR"];
				cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
				
				break;
				
				
			}
				
				
			default:
				break;
		}
		
		
		
		
		return cell;
	}
	else 
	{
		// summary for one app
		cell.CELL_IMAGE = rowApp.iconImageNano;
		
		cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", [report  sumUnitsForProduct:rowApp transactionType:TransactionTypeSale]];
		cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", [report sumUnitsForProduct:rowApp transactionType:TransactionTypeFreeUpdate]];
		NSInteger refunds = [report  sumRefundsForAppId:rowApp.apple_identifier];
		if (refunds)
		{
			cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", refunds];
		}
		else
		{
			cell.unitsRefundedLabel.text = @"";
		}
		
		double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report sumRoyaltiesForProduct:rowApp transactionType:TransactionTypeSale] fromCurrency:@"EUR"];
		cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
		
		return cell;
	}
	
	return cell;
	
	/*
	
	NSArray *dictKeys = [thisDict keysSortedByValueUsingSelector:@selector(compareBySales:)];  // all countries
	CountrySummary *tmpSummary = [thisDict objectForKey:[dictKeys objectAtIndex:indexPath.row-1]];
	
	cell.CELL_IMAGE = tmpSummary.country.iconImage;
	
	
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
	//cell.CELL_IMAGE = tmpSale.country.iconImage;
	
	//NSLog( [NSString stringWithFormat:@"%@ s: %d = %.2f %@, u: %d, r: %d",  tmpSummary.country.iso3,tmpSummary.sumSales, tmpSummary.sumRoyalites, tmpSummary.royaltyCurrency, tmpSummary.sumUpdates, tmpSummary.sumRefunds]);
	//NSLog(@"ok");
    return cell;
	 */
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (!indexPath.row) return;
	
	GenericReportController *genericReportController = [[GenericReportController alloc] initWithReport:self.report];

	switch (indexPath.section) {
		case 0:
		{
			genericReportController.title = @"All Products";
			break;
		}
		default:
		{
			App *app =  [sortedApps objectAtIndex:indexPath.section-1];
			
			if ([app inAppPurchases])
			{
				genericReportController.title = app.title;

				switch (indexPath.row) 
				{
					case 1:
						// app + iap
						genericReportController.filteredApp = app;  // shows both
						break;
					case 2:
						// app
						[genericReportController setFilteredApp:app showApps:YES showIAPs:NO];
						break;
					case 3:
						// iap
						[genericReportController setFilteredApp:app showApps:NO showIAPs:YES];
						break;
					default:
						break;
				}
			}
			else
			{
				// app
				[genericReportController setFilteredApp:app showApps:YES showIAPs:NO];
				break;
			}

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






#pragma mark Actions
- (void) upDownPushed:(id)sender
{
	// cannot use sender for some reason, we get exception when accessing properties
	
	if (segmentedControl.selectedSegmentIndex == 0)
	{
		Report *newReport = [[Database sharedInstance] reportNewerThan:report];
		[self setReport:newReport];
	}
	else
	{
		Report *newReport = [[Database sharedInstance] reportOlderThan:report];
		[self setReport:newReport];
	}
}


@end

