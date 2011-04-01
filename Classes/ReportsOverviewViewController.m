//
//  ReportsOverviewViewController.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 05.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "ReportsOverviewViewController.h"
#import "CoreDatabase.h"
#import "YahooFinance.h"
#import "Report+Custom.h"
#import "SingleReportViewController.h"

@interface ReportsOverviewViewController ()

@property (nonatomic, retain) NSDateFormatter *cellDateFormatter;
@property (nonatomic, retain) NSDateFormatter *sectionNameDateFormatter;
@property (nonatomic, retain) NSDateFormatter *sectionNameDateParser;

@end



@implementation ReportsOverviewViewController


#pragma mark -
#pragma mark Initialization

- (id)initWithProductGroup:(ProductGroup *)productGroup reportType:(ReportType)reportType
{
	if ((self = [super initWithStyle:UITableViewStylePlain]))
	{
		_productGroup = [productGroup retain];
		_reportType = reportType;
		
		self.navigationItem.title = _productGroup.title;
		
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
	
	[fetchedResultsController release];
	[cellDateFormatter release];
	
    [super dealloc];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath 
{
	Report *report = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	switch (_reportType) 
	{
		case ReportTypeDay:
		case ReportTypeWeek:
		default:
		{
			cell.textLabel.text = [self.cellDateFormatter stringFromDate:report.fromDate];
			break;
		}
		case ReportTypeFree:
		case ReportTypeFinancial:
		{
			cell.textLabel.text = NSStringFromReportRegion([report.region intValue]);
		}
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RoyaltyTotalsOnOverView"])
	{
		
		ReportSummary *summary = report.totalSummary;
		if (!summary)
		{
			// building summary causes fetched result controller to receive changes
			ignoreFetchedResultControllerNotifications = YES;
			summary = [[CoreDatabase sharedInstance] summaryForReport:report];
			ignoreFetchedResultControllerNotifications = NO;
		}
		double amount = [summary.sumRoyalties doubleValue];
		
		// convert sum
		amount = [[YahooFinance sharedInstance] convertToMainCurrencyAmount:amount fromCurrency:@"EUR"];
		cell.detailTextLabel.text = [[YahooFinance sharedInstance] formatAsMainCurrencyAmount:amount];
	}
	
	// only show disclosure if there are sales on this report
	if ([report.sales count])
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	if ([report.isNew boolValue])
	{
		cell.imageView.image = [UIImage imageNamed:@"Report_Icon_New.png"];
	}
	else 
	{
		cell.imageView.image = [UIImage imageNamed:@"Report_Icon.png"];
	}
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [[self.fetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	
    return [sectionInfo	numberOfObjects];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	
	NSString *sectionName = [sectionInfo name];
    NSDate *sectionDate = [self.sectionNameDateParser dateFromString:sectionName];
	
	return [self.sectionNameDateFormatter stringFromDate:sectionDate];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	[self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
		// [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		Report *report = [self.fetchedResultsController objectAtIndexPath:indexPath];
		[[CoreDatabase sharedInstance] removeReport:report];
		
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}



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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// short back bar title
	NSString *backTitle = NSStringFromReportType(_reportType);
	
	NSArray *comps = [backTitle componentsSeparatedByString:@" "];
	if ([comps count]>1)
	{
		backTitle = [comps objectAtIndex:0];
	}
	
	self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:backTitle
																			  style:UIBarButtonItemStyleBordered
																			 target:nil
																			 action:nil] autorelease];
	
	
	Report *report = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	SingleReportViewController *vc = [[[SingleReportViewController alloc] initWithReport:report] autorelease];
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark Fetched results controller
- (NSFetchedResultsController *)fetchedResultsController 
{
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
	NSManagedObjectContext *moc = [CoreDatabase sharedInstance].managedObjectContext;
	
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Report" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
	
	// filter only the product group we passed
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"productGrouping == %@ AND reportType == %d", _productGroup, _reportType];
	[fetchRequest setPredicate:predicate];
	
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:30];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[[NSSortDescriptor alloc] initWithKey:@"fromDate" ascending:NO] autorelease];
    NSSortDescriptor *sortDescriptor2 = [[[NSSortDescriptor alloc] initWithKey:@"region" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor1, sortDescriptor2, nil] autorelease];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
	
	NSString *cacheName = [NSString stringWithFormat:@"ReportOverview;%@;%d", _productGroup.identifier, _reportType];
	
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
																								managedObjectContext:moc 
																								  sectionNameKeyPath:@"yearMonth" 
																										   cacheName:cacheName];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
	
	// initial fetch
    NSError *error = nil;
    if (![aFetchedResultsController performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
	
    return fetchedResultsController;
} 

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{
	if (ignoreFetchedResultControllerNotifications) return;
	
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type 
{
	if (ignoreFetchedResultControllerNotifications) return;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath 
{
	if (ignoreFetchedResultControllerNotifications) return;
	
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(id)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
	if (ignoreFetchedResultControllerNotifications) return;
	
    [self.tableView endUpdates];
}

#pragma mark Notifications

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

- (NSDateFormatter *)cellDateFormatter
{
	if (!cellDateFormatter)
	{
		cellDateFormatter = [[NSDateFormatter alloc] init];
		
		switch (_reportType) 
		{
			case ReportTypeDay:
				[cellDateFormatter setDateStyle:NSDateFormatterLongStyle];
				[cellDateFormatter setTimeStyle:NSDateFormatterNoStyle];
				break;
			case ReportTypeWeek:
				[cellDateFormatter setDateFormat:@"'Week' w '('MMM dd')'"];
				break;
			default:
				break;
		}
		
	}
	
	return cellDateFormatter;
}

- (NSDateFormatter *)sectionNameDateParser
{
	if (!sectionNameDateParser)
	{
		sectionNameDateParser = [[NSDateFormatter alloc] init];
		[sectionNameDateParser setDateFormat:@"yyyy-MM"];
	}
	
	return sectionNameDateParser;
}

- (NSDateFormatter *)sectionNameDateFormatter
{
	if (!sectionNameDateFormatter)
	{
		sectionNameDateFormatter = [[NSDateFormatter alloc] init];
		[sectionNameDateFormatter setDateFormat:@"MMMM yyyy"];
	}
	
	return sectionNameDateFormatter;
}

@synthesize fetchedResultsController;
@synthesize cellDateFormatter;
@synthesize sectionNameDateFormatter;
@synthesize sectionNameDateParser;

@end

