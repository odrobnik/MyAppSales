//
//  SingleReportViewController.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 05.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "SingleReportViewController.h"
#import "ReportDetailViewController.h"

#import "CoreDatabase.h"
#import "ReportCell.h"
#import "YahooFinance.h"

#import "Report+Custom.h"

@interface SingleReportViewController ()

@property (nonatomic, retain) NSArray *apps;

@end


@implementation SingleReportViewController


#pragma mark -
#pragma mark Initialization



- (id)initWithReport:(Report *)report
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) 
	{
		self.report = report;
		
		if (![_report.summaries count])
		{
			[[CoreDatabase sharedInstance] buildSummaryForReport:_report];
		}
		
		self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:[_report shortTitleForBackButton]
																				  style:UIBarButtonItemStyleBordered
																				 target:nil
																				 action:nil] autorelease];
		
		
		
		// get the apps sorted by royalties and title
		NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"sumRoyalties" ascending:NO];
		NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"sumSales" ascending:NO];
		NSSortDescriptor *sort3 = [NSSortDescriptor sortDescriptorWithKey:@"sumUpdates" ascending:NO];
		NSSortDescriptor *sort4 = [NSSortDescriptor sortDescriptorWithKey:@"product.title" ascending:YES];
		
		NSArray *descriptors = [NSArray arrayWithObjects:sort1, sort2, sort3, sort4, nil];
		apps = [[_report.appSummaries sortedArrayUsingDescriptors:descriptors] retain];
		
		// refresh table if main currency has changed
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainCurrencyChanged:) name:@"MainCurrencyChanged" object:nil];
    }
    return self;
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_report release];
	[apps release];
	
	[sortedSummaries release];
    [super dealloc];
}

#pragma mark Summing / Cells
- (NSArray *)summaryTotalsFilteredForProduct:(Product *)product includeChildren:(BOOL)includeChildren
{
	NSSet *filteredSet;
	
	if (product)
	{
		if (!includeChildren)
		{
			NSPredicate *pred = [NSPredicate predicateWithFormat:@"product = %@ and country == nil", product];
			filteredSet = [_report.summaries filteredSetUsingPredicate:pred];
		}
		else 
		{
			NSPredicate *pred = [NSPredicate predicateWithFormat:@"(product = %@ or product.parent = %@) and country == nil", product, product];
			filteredSet = [_report.summaries filteredSetUsingPredicate:pred];
		}
		
	}
	else 
	{
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"product != nil and country == nil", product];
		filteredSet = [_report.summaries filteredSetUsingPredicate:pred];
	}
	
	
	// get the apps sorted by royalties and title
	NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"sumRoyalties" ascending:NO];
	NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"sumSales" ascending:NO];
	NSSortDescriptor *sort3 = [NSSortDescriptor sortDescriptorWithKey:@"sumUpdates" ascending:NO];
	NSSortDescriptor *sort4 = [NSSortDescriptor sortDescriptorWithKey:@"product.title" ascending:YES];
	
	NSArray *descriptors = [NSArray arrayWithObjects:sort1, sort2, sort3, sort4, nil];
	return [filteredSet sortedArrayUsingDescriptors:descriptors];
}

- (NSArray *)summaryTotalsFilteredForChildrenOfProduct:(Product *)product
{
	NSSet *filteredSet;
	
	if (product)
	{
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"product.parent = %@ and product != nil and country == nil", product];
		filteredSet = [_report.summaries filteredSetUsingPredicate:pred];
	}
	else 
	{
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"product.parent != nil and country == nil", product];
		filteredSet = [_report.summaries filteredSetUsingPredicate:pred];
	}
	
	// get the apps sorted by royalties and title
	NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"sumRoyalties" ascending:NO];
	NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"sumSales" ascending:NO];
	NSSortDescriptor *sort3 = [NSSortDescriptor sortDescriptorWithKey:@"sumUpdates" ascending:NO];
	NSSortDescriptor *sort4 = [NSSortDescriptor sortDescriptorWithKey:@"product.title" ascending:YES];
	
	NSArray *descriptors = [NSArray arrayWithObjects:sort1, sort2, sort3, sort4, nil];
	return [filteredSet sortedArrayUsingDescriptors:descriptors];
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
	royalties = [yahoo convertToMainCurrencyAmount:royalties
									  fromCurrency:summary.royaltyCurrency];
	
	
	cell.royaltyEarnedLabel.text = [yahoo formatAsCurrency:yahoo.mainCurrency
													amount:royalties];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

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
	
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [apps count] + 1; // overall total section at top
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (!section)
	{
		return @"Total Summary";
	}
	
	ReportSummary *sectionSummary = [apps objectAtIndex:section-1];
	
	return sectionSummary.product.title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	// always 1 more for a section header
	if (!section)
	{
		return 2;  // total section
	}
	
	ReportSummary *sectionSummary = [apps objectAtIndex:section-1];
	
	if (sectionSummary.childrenSummary)
	{
		// IAP schows 3 rows
		return 4;
	}
	
	// no IAPs shows 1 row
    return 2;
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
	
	// total summary cell
	if (!indexPath.section)
	{
		[self configureCell:cell withSummary:_report.totalSummary];
		
		// leads to list with all products and all countries
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		cell.imageView.image = [UIImage imageNamed:@"Sum.png"];
		return cell;
	}
	
	ReportSummary *sectionSummary = [apps objectAtIndex:indexPath.section-1];
	
	if (sectionSummary.childrenSummary)
	{
		switch (indexPath.row) 
		{
			case 0:
			{
				// header
				break;
			}
			case 1:
			{
				// app+IAP sum
				[self configureCell:cell withSummary:sectionSummary plusSummary:sectionSummary.childrenSummary];
				
				cell.imageView.image = [UIImage imageNamed:@"Sum.png"];
				
				break;
			}
			case 2:
			{
				// sum of app alone
				UIImage *image = [[CoreDatabase sharedInstance] iconImageForProduct:sectionSummary.product];
				image = [image imageByScalingToSize:CGSizeMake(32, 32)];
				cell.imageView.image = image;
				
				[self configureCell:cell withSummary:sectionSummary];
				
				break;
			}
			case 3:
			{
				// sum of IAPs
				cell.imageView.image = [UIImage imageNamed:@"iap_nano.png"];
				
				[self configureCell:cell withSummary:sectionSummary.childrenSummary];
				
				break;
			}
		}
	}
	else 
	{
		if (indexPath.row)
		{
			UIImage *image = [[CoreDatabase sharedInstance] iconImageForProduct:sectionSummary.product];
			image = [image imageByScalingToSize:CGSizeMake(32, 32)];
			cell.imageView.image = image;
			
			[self configureCell:cell withSummary:sectionSummary];
		}
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSString *title = nil;
	
	NSMutableArray *summaries = [NSMutableArray array];
	
	if (!indexPath.section)
	{
		// first row is total
		[summaries addObject:_report.totalSummary];
		
		NSArray *tmpArray = [self summaryTotalsFilteredForProduct:nil includeChildren:YES];
		
		[summaries addObjectsFromArray:tmpArray];
		
		title = _report.productGrouping.title;
	}
	else 
	{
		// clicked on one of the app rows
		ReportSummary *sectionSummary = [apps objectAtIndex:indexPath.section-1];
		
		if (sectionSummary.childrenSummary)
		{
			switch (indexPath.row) 
			{
				case 0:
				{
					// header
					return;
				}
				case 1:
				{
					// app+IAP sum
					NSArray *array = [NSArray arrayWithObjects:sectionSummary, sectionSummary.childrenSummary, nil];
					
					[summaries addObject:array];
					
					
					NSArray *tmpArray = [self summaryTotalsFilteredForProduct:sectionSummary.product includeChildren:YES];
					[summaries addObjectsFromArray:tmpArray];
					
					title = sectionSummary.product.title;
					
					break;
				}
				case 2:
				{
					// sum of app alone
					
					NSArray *tmpArray = [self summaryTotalsFilteredForProduct:sectionSummary.product includeChildren:NO];
					[summaries addObjectsFromArray:tmpArray];
					
					title = sectionSummary.product.title;

					
					break;
				}
				case 3:
				{
					// sum of IAP alone
					
					if ([sectionSummary.product.children count]>1)
					{
						[summaries addObject:sectionSummary.childrenSummary];
					}
					
					NSArray *tmpArray = [self summaryTotalsFilteredForChildrenOfProduct:sectionSummary.product];
					[summaries addObjectsFromArray:tmpArray];
					
					title = sectionSummary.product.title;
					
					break;
				}
			}
			
		}
		else 
		{
			// only app, no IAP
			NSArray *tmpArray = [self summaryTotalsFilteredForProduct:sectionSummary.product includeChildren:NO];
			[summaries addObjectsFromArray:tmpArray];
			
			title = sectionSummary.product.title;

		}

	}
	
	ReportDetailViewController *vc = [[[ReportDetailViewController alloc] initWithSectionSummaries:summaries] autorelease];
	vc.navigationItem.title = title;
	[self.navigationController pushViewController:vc animated:YES];
}


#pragma mark Notifications
- (void)mainCurrencyChanged:(NSNotification *)notification
{
	// all sums should now be displayed with new currency
	[self.tableView reloadData];
}

#pragma mark Properties

@synthesize report = _report;
@synthesize apps;

@end

