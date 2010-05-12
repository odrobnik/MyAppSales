//
//  GenericReportController.m
//  ASiST
//
//  Created by Oliver Drobnik on 29.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "GenericReportController.h"
#import "Report.h"
#import "Sale.h"
#import "Country.h"
#import "App.h"
#import "InAppPurchase.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
//#import "iTunesConnect.h"
#import "CountrySummary.h"
#import "ReportCell.h"

@implementation GenericReportController

@synthesize filteredApp;

- (id) initWithReport:(Report *)aReport
{
	if (self = [super initWithStyle:UITableViewStylePlain]) {
		report = aReport;
		[report hydrate];
		self.title = [aReport listDescriptionShorter:NO];
		sumImage = [UIImage imageNamed:@"Sum.png"];
		filteredApp = nil;
		
		shouldShowApps = YES;
		shouldShowIAPs = YES;
		sortedProducts = [[DB productsSortedBySalesForGrouping:report.appGrouping] retain];
    }
    return self;
}

- (void)dealloc 
{
	[sortedProducts release];
	[filteredApp release];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if ([sortedProducts count]>1)
	{
		return [sortedProducts count] + 1; // one extra section for totals over all apps
	}
	else
	{
		return [sortedProducts count]; // one extra section for totals over all apps
	}

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	/*
	// if we want to see only one app, then ...
	if (filteredApp)
	{
		return nil;
	}
	*/
	//ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	// section 0 = totals
	
	if ([sortedProducts count]==1)
	{
		if ([[sortedProducts lastObject] isKindOfClass:[App class]])
		{
			return nil; // we skip header
		}
		else
		{
			section++;
		}

	}
	
	if (section)
	{
		App *tmpApp = [sortedProducts objectAtIndex:section - 1];  // minus one because of totals section
		//NSNumber *app_id = [NSNumber numberWithInt:tmpApp.apple_identifier];  // minus one because of totals section
		
		if (tmpApp)
		{
			if ([tmpApp isKindOfClass:[InAppPurchase class]])
			{
				return [NSString stringWithFormat:@"%@ (IAP)", tmpApp.title];
			}
			else
			{
				return tmpApp.title;
			}
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
	/*
	// we filter for one app
	if (filteredApp)
	{
		NSNumber *app_id = [NSNumber numberWithInt:filteredApp.apple_identifier];  // minus one because of totals section
		
		NSArray *thisArray = [report.summariesByApp objectForKey:app_id];
		return [thisArray count]+1+1;  // add one for app summary plus one for header
	}
	 */
	
	if ([sortedProducts count]==1)
	{
		section++; // we skip header
	}
	
	// we don't filter
	if (section)
	{
		Product_v1 *sectionProduct= [sortedProducts objectAtIndex:section - 1];  // minus one because of totals section
		
		
		NSArray *thisArray = [report.summariesByApp objectForKey:[sectionProduct identifierAsNumber]];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
    static NSString *CellIdentifier;
	
	if (!indexPath.row)  // first row is summary row
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
	App *rowApp = nil;
	
	/*
	if (filteredApp)
	{
		app_id = [NSNumber numberWithInt:filteredApp.apple_identifier];
		rowApp = filteredApp;
	}
	 
	else

	 */
	
	NSUInteger section = indexPath.section;
	
	if ([sortedProducts count]==1)
	{
		section++; // we skip header
	}
	
	 {
		if (!section)   // extra section for totals over all apps
		{
			if (!indexPath.row)  // first row is header row
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
				cell.CELL_IMAGE = sumImage;
				cell.countryCodeLabel.text = @"";
				
				if (filteredApp)
				{
					NSInteger units = 0;
					double royalties = 0;
					NSInteger updates = 0;
					NSInteger refunds = 0;

					
					if (shouldShowApps)
					{
						units += [report sumUnitsForProduct:filteredApp transactionType:TransactionTypeSale];
						royalties += [report sumRoyaltiesForProduct:filteredApp transactionType:TransactionTypeSale];
						updates += [report sumUnitsForProduct:filteredApp transactionType:TransactionTypeFreeUpdate];
						refunds += [report sumRefundsForProduct:filteredApp];

					}
					
					if (shouldShowIAPs)
					{
						units += [report sumUnitsForInAppPurchasesOfApp:filteredApp];;
						royalties += [report sumRoyaltiesForInAppPurchasesOfApp:filteredApp];
					}
					
					
					cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", units];
					cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", updates];
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
				else
				{
					cell.CELL_IMAGE = sumImage;
					
					NSInteger units = [report sumUnitsForProduct:nil transactionType:TransactionTypeSale] +
					[report sumUnitsForProduct:nil transactionType:TransactionTypeIAP];			
					
					double royalties = [report sumRoyaltiesForProduct:nil transactionType:TransactionTypeSale] +
					[report sumRoyaltiesForProduct:nil transactionType:TransactionTypeIAP];
					
					NSInteger updates = [report sumUnitsForProduct:nil transactionType:TransactionTypeFreeUpdate];
					cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", units];
					cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", updates];
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

				
			}
			return cell;
		}
		
		
		// below this line: detail lines
		
		rowApp = [sortedProducts objectAtIndex:section - 1];  // minus one because of totals section
		app_id = [NSNumber numberWithInt:rowApp.apple_identifier];  // minus one because of totals section
		
	}	
	
	if (indexPath.row==1)
	{ // summary
		
		cell.CELL_IMAGE = sumImage;
		cell.countryCodeLabel.text = @"";
		
		if ([rowApp isKindOfClass:[InAppPurchase class]])
		{
			cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d",[report sumUnitsForProduct:rowApp transactionType:TransactionTypeIAP]];
			double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report sumRoyaltiesForProduct:rowApp transactionType:TransactionTypeIAP] fromCurrency:@"EUR"];
			cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
		}
		else
		{
			cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", [report sumUnitsForProduct:rowApp transactionType:TransactionTypeSale]];
			double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[report sumRoyaltiesForProduct:rowApp transactionType:TransactionTypeSale] fromCurrency:@"EUR"];
			cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
		}

		cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", [report sumUnitsForProduct:rowApp transactionType:TransactionTypeFreeUpdate]];
		NSInteger refunds = [report  sumRefundsForProduct:rowApp];
		if (refunds)
		{
			cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", refunds];
		}
		else
		{
			cell.unitsRefundedLabel.text = @"";
		}
		
		
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
	cell.CELL_IMAGE = tmpSummary.country.iconImage;
	cell.countryCodeLabel.text = tmpSummary.country.iso3;
	
	
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


#pragma mark Filtering

- (void) setFilteredApp:(App *)app
{
	if (filteredApp!=app)
	{
		[filteredApp release];
		filteredApp = [app retain];
		
		// take all products for this grouping and boil it down to filtered app-related
		
		NSArray *allProducts = [DB productsSortedBySalesForGrouping:report.appGrouping];
		NSMutableArray *filteredProducts = [NSMutableArray array];
		
		for (Product_v1 *oneProduct in allProducts)
		{
			if ((oneProduct == app)||([oneProduct isKindOfClass:[InAppPurchase class]]&&((InAppPurchase *)oneProduct).parent == app))
			{
				[filteredProducts addObject: oneProduct];
			}
		}
		
		[sortedProducts release];
		sortedProducts = [filteredProducts retain];
		
		self.title = filteredApp.title;
		
		[self.tableView reloadData];
	}
}

- (void) setFilteredApp:(App *)app showApps:(BOOL)showApps showIAPs:(BOOL)showIAPs
{
	if (filteredApp!=app)
	{
		[filteredApp release];
		filteredApp = [app retain];

		self.title = filteredApp.title;
		
		shouldShowApps = showApps;
		shouldShowIAPs = showIAPs;
		
		// take all products for this grouping and boil it down to filtered app-related
		
		NSArray *allProducts = [DB productsSortedBySalesForGrouping:report.appGrouping];
		NSMutableArray *filteredProducts = [NSMutableArray array];
		
		for (Product_v1 *oneProduct in allProducts)
		{
			if ((oneProduct == app)||([oneProduct isKindOfClass:[InAppPurchase class]]&&((InAppPurchase *)oneProduct).parent == app))
			{
				if ((showApps&&[oneProduct isKindOfClass:[App class]])||(showIAPs&&[oneProduct isKindOfClass:[InAppPurchase class]]))
				{
					[filteredProducts addObject: oneProduct];
				}
			}
		}
		
		[sortedProducts release];
		sortedProducts = [filteredProducts retain];
		
		[self.tableView reloadData];
	}
}


@end

