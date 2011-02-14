//
//  ReportDetailViewController.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 06.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "ReportDetailViewController.h"

#import "CoreDatabase.h"
#import "ReportCell.h"
#import "YahooFinance.h"

@implementation ReportDetailViewController


#pragma mark -
#pragma mark Initialization


- (id)initWithSectionSummaries:(NSArray *)summaries
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) 
	{
		self.summaries = summaries;
		
		// sort the children
		_childrenSorted = [[NSMutableArray alloc] init];

		// get the apps sorted by royalties and title
		NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"sumRoyalties" ascending:NO];
		NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"sumSales" ascending:NO];
		NSSortDescriptor *sort3 = [NSSortDescriptor sortDescriptorWithKey:@"sumUpdates" ascending:NO];
		NSSortDescriptor *sort4 = [NSSortDescriptor sortDescriptorWithKey:@"country.name" ascending:YES];
		
		NSArray *descriptors = [NSArray arrayWithObjects:sort1, sort2, sort3, sort4, nil];
		
		
		for (ReportSummary *summary in _summaries)
		{
			if (![summary isKindOfClass:[ReportSummary class]] || !summary.children)
			{
				[_childrenSorted addObject:[NSNull null]];
			}
			else 
			{
				NSArray *children = [summary.children sortedArrayUsingDescriptors:descriptors];
				
				[_childrenSorted addObject:children];
			}
		}
		

		// refresh table if a country flag is loaded
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(countryFlagLoaded:) name:@"CountryFlagLoaded" object:nil];
		
		// refresh table if main currency has changed
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainCurrencyChanged:) name:@"MainCurrencyChanged" object:nil];
		
		// if defaults setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_summaries release];
	[_childrenSorted release];
    [super dealloc];
}


#pragma mark -
#pragma mark View lifecycle

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
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source
- (void)configureCell:(ReportCell *)cell withSummary:(ReportSummary *)summary plusSummary:(ReportSummary *)plusSummary
{
	NSInteger unitsSold = [summary.sumSales intValue] + [plusSummary.sumSales intValue];
	NSInteger unitsRefunded = [summary.sumRefunds intValue] + [plusSummary.sumRefunds intValue];
	NSInteger unitsUpdated = [summary.sumUpdates intValue] + [plusSummary.sumUpdates intValue];
	
	cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d", unitsSold];
	
	if (unitsRefunded)
	{
		cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", unitsRefunded];
	}
	else 
	{
		cell.unitsRefundedLabel.text = nil;
	}
	
	cell.unitsUpdatedLabel.text = [NSString stringWithFormat:@"%d", unitsUpdated];
	
	double royalties = [summary.sumRoyalties doubleValue] + [plusSummary.sumRoyalties doubleValue];
	
	YahooFinance *yahoo = [YahooFinance sharedInstance];
	royalties = [yahoo convertToMainCurrencyAmount:royalties
									  fromCurrency:summary.royaltyCurrency];
	
	
	cell.royaltyEarnedLabel.text = [yahoo formatAsCurrency:yahoo.mainCurrency
													amount:royalties];
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	if (summary.country)
	{
		cell.countryCodeLabel.text = summary.country.iso3;
		
		UIImage *image = [[CoreDatabase sharedInstance] flagImageForCountry:summary.country];
		cell.imageView.image = [image imageByScalingToSize:CGSizeMake(32, 32)];
	}
	else 
	{
		cell.imageView.image = [UIImage imageNamed:@"Sum.png"];
		cell.countryCodeLabel.text = nil;
	}
}

- (void)configureCell:(ReportCell *)cell withSummary:(ReportSummary *)summary
{
	cell.unitsSoldLabel.text = [summary.sumSales description];
	cell.unitsUpdatedLabel.text = [summary.sumUpdates description];
	
	NSInteger unitsRefunded = [summary.sumRefunds intValue];
	if (unitsRefunded)
	{
		cell.unitsRefundedLabel.text = [NSString stringWithFormat:@"%d", unitsRefunded];
	}
	else 
	{
		cell.unitsRefundedLabel.text = nil;
	}
	
	double royalties = [summary.sumRoyalties doubleValue];
	
	YahooFinance *yahoo = [YahooFinance sharedInstance];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	if (summary.country)
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AlwaysUseMainCurrency"])
		{
			royalties = [yahoo convertToMainCurrencyAmount:royalties
											  fromCurrency:summary.royaltyCurrency];
			
			
			cell.royaltyEarnedLabel.text = [yahoo formatAsCurrency:yahoo.mainCurrency
															amount:royalties];
		}
		else 
		{
			cell.royaltyEarnedLabel.text = [yahoo formatAsCurrency:summary.royaltyCurrency
															amount:royalties];
		}

		cell.countryCodeLabel.text = summary.country.iso3;
		
		UIImage *image = [[CoreDatabase sharedInstance] flagImageForCountry:summary.country];
		cell.imageView.image = [image imageByScalingToSize:CGSizeMake(32, 32)];
	}
	else 
	{
		royalties = [yahoo convertToMainCurrencyAmount:royalties
										  fromCurrency:summary.royaltyCurrency];
		
		
		cell.royaltyEarnedLabel.text = [yahoo formatAsCurrency:yahoo.mainCurrency
														amount:royalties];
		cell.imageView.image = [UIImage imageNamed:@"Sum.png"];
		cell.countryCodeLabel.text = nil;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [_summaries count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	ReportSummary *sectionSummary = [_summaries objectAtIndex:section];
	
	if (![sectionSummary isKindOfClass:[ReportSummary class]])
	{
		// is a merged total
		return 2;
	}
	
	return 2 + [sectionSummary.children count];

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// no title if it's just one app
	if ([self numberOfSectionsInTableView:tableView]==1)
	{
		return nil;
	}
	
	ReportSummary *sectionSummary = [_summaries objectAtIndex:section];
	
	if (![sectionSummary isKindOfClass:[ReportSummary class]])
	{
		return @"Total Summary";
	}
	
	if (sectionSummary.product)
	{
		if ([sectionSummary.product.isInAppPurchase boolValue])
		{
			if ([sectionSummary.children count])
			{
				return [NSString stringWithFormat:@"%@ (IAP)", sectionSummary.product.title];
			}
		}
		else 
		{
			return sectionSummary.product.title;
		}
	}
	
	return @"Total Summary";
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
	
	// first row is always header
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
    
    // Configure the cell...
	
	if (indexPath.row==1)
	{
		ReportSummary *summary = [_summaries objectAtIndex:indexPath.section];

		// if it's an array we need to add the sums
		if ([summary isKindOfClass:[NSArray class]])
		{
			NSArray *tmpArray = (id)summary;
			
			ReportSummary *part1 = [tmpArray objectAtIndex:0];
			ReportSummary *part2 = [tmpArray objectAtIndex:1];
			
			[self configureCell:cell withSummary:part1 plusSummary:part2];
			return cell;
		}
		else 
		{
			ReportSummary *summary = [_summaries objectAtIndex:indexPath.section];
			[self configureCell:cell withSummary:summary];
			return cell;
		}
	}
	
	NSArray *children = [_childrenSorted objectAtIndex:indexPath.section];
	
	ReportSummary *summary = [children objectAtIndex:indexPath.row - 2];
	[self configureCell:cell withSummary:summary];
	return cell;
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
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

#pragma mark Notifications
- (void)countryFlagLoaded:(NSNotification *)notification
{
	[self.tableView reloadData];
}

- (void)mainCurrencyChanged:(NSNotification *)notification
{
	// all sums should now be displayed with new currency
	[self.tableView reloadData];
}

- (void)defaultsChanged:(NSNotification *)notification
{
	// all sums should now be displayed or not displayed
	[self.tableView reloadData];
}


#pragma mark Properties


@synthesize summaries = _summaries;

@end

