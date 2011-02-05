//
//  ReportsGroupsAndTypeSelectionViewController.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 03.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "ReportsGroupsAndTypeSelectionViewController.h"

#import "Report+Custom.h"
#import "MyAppSalesAppDelegate.h"

#import "ReportsOverviewViewController.h"

@interface ReportsGroupsAndTypeSelectionViewController ()

@property (nonatomic, retain) NSArray *productGroupIndex;

@end



@implementation ReportsGroupsAndTypeSelectionViewController


#pragma mark -
#pragma mark Initialization

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 self = [super initWithStyle:style];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */

- (void)dealloc 
{
	[fetchedResultsController release];
	[productGroupIndex release];
	[reloadButtonItem release];
	
    [super dealloc];
}



#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad 
{
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchingDone:) name:@"AllDownloadsFinished" object:nil];
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
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


#pragma mark -
#pragma mark Table view data source




- (NSArray *)productGroupIndex
{
	if (!productGroupIndex)
	{
		NSMutableDictionary *groups = [NSMutableDictionary dictionary];
		
		for (id <NSFetchedResultsSectionInfo> sectionInfo in [self.fetchedResultsController sections])
		{
			NSString *sectionKey = [sectionInfo name];
			NSArray *components = [sectionKey componentsSeparatedByString:@"\t"];
			NSString *groupName = [components objectAtIndex:0];
			NSString *typeString = [components objectAtIndex:1];
			NSString *groupID = [components objectAtIndex:2];
			
			NSMutableDictionary *groupDict = [groups objectForKey:groupName];
			
			if (!groupDict)
			{
				groupDict = [NSMutableDictionary dictionary];
				[groups setObject:groupDict forKey:groupName];
				
				[groupDict setObject:groupName forKey:@"groupName"];
				[groupDict setObject:groupID forKey:@"groupID"];
			}
			
			NSInteger count = [sectionInfo numberOfObjects];
			
			[groupDict setObject:[NSNumber numberWithInt:count] forKey:typeString];
		}
		
		NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"groupName" ascending:YES];
		self.productGroupIndex = [[groups allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
		
	}
	
	return productGroupIndex;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
{
	NSDictionary *productGroup = [self.productGroupIndex objectAtIndex:section];
	
	return [productGroup objectForKey:@"groupName"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self.productGroupIndex count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	NSDictionary *productGroup = [self.productGroupIndex objectAtIndex:section];
	
	return [[productGroup allKeys] count]-2;  // one is name, another is group id
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	NSDictionary *productGroup = [self.productGroupIndex objectAtIndex:indexPath.section];
	
	NSArray *keys = [productGroup allKeys];
	
	NSArray *typeKeys = [keys sortedArrayUsingSelector:@selector(compare:)];
	
	NSNumber *rowKey = [typeKeys objectAtIndex:indexPath.row];
	NSNumber *rowCount = [productGroup objectForKey:rowKey];

	
	
	cell.textLabel.text = NSStringFromReportType([rowKey intValue]);
	cell.detailTextLabel.text = [rowCount description];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	NSString *groupID = [productGroup objectForKey:@"groupID"];
	
	if ([[CoreDatabase sharedInstance] hasNewReportsOfType:[rowKey intValue] productGroupID:groupID])
	{
		cell.imageView.image = [UIImage imageNamed:@"Report_Icon_New.png"];
	}
	else 
	{
		cell.imageView.image = [UIImage imageNamed:@"Report_Icon.png"];
	}

	
  
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *productGroupDict = [self.productGroupIndex objectAtIndex:indexPath.section];
	
	NSArray *keys = [productGroupDict allKeys];
	
	NSArray *typeKeys = [keys sortedArrayUsingSelector:@selector(compare:)];
	
	NSNumber *rowKey = [typeKeys objectAtIndex:indexPath.row];
	NSString *groupID = [productGroupDict objectForKey:@"groupID"];
	
	ReportType reportType = [rowKey intValue];
	
	ProductGroup *productGroup = [[CoreDatabase sharedInstance] productGroupForKey:groupID];
	
	ReportsOverviewViewController *overview = [[[ReportsOverviewViewController alloc] initWithProductGroup:productGroup reportType:reportType] autorelease];
	[self.navigationController pushViewController:overview animated:YES];
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
	
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[[NSSortDescriptor alloc] initWithKey:@"productGrouping.title" ascending:YES] autorelease];
    NSSortDescriptor *sortDescriptor2 = [[[NSSortDescriptor alloc] initWithKey:@"reportType" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor1, sortDescriptor2, nil] autorelease];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
																								managedObjectContext:moc 
																								  sectionNameKeyPath:@"sectionKey" cacheName:@"ReportsBySectionKey"];
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
	self.productGroupIndex = nil;
	[self.tableView reloadData];
}

#pragma mark Actions
- (void)reloadReports:(id)sender
{
	MyAppSalesAppDelegate *appDelegate = (MyAppSalesAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate startSync];
}

- (void) reloadTableViewDataSource
{
	MyAppSalesAppDelegate *appDelegate = (MyAppSalesAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate startSync];
}

- (void)synchingDone:(NSNotification *)notification
{
	//refreshHeaderView.lastUpdatedDate = _product.lastReviewRefresh;
	//[super dataSourceDidFinishLoadingNewData];
}

@synthesize productGroupIndex;
@synthesize fetchedResultsController;
@synthesize reloadButtonItem;

@end

