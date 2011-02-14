//
//  ApplicationsViewController.m
//  ASiST
//
//  Created by Oliver on 27.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "ApplicationsViewController.h"
#import "ApplicationReviewsViewController.h"

#import "ApplicationCell.h"
#import "YahooFinance.h"

#import "Product.h"
#import "Product+Custom.h"
#import "ProductSummary.h"

#import "UIImage+MyAppSales.h"

@implementation ApplicationsViewController


/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appIconLoaded:) name:@"AppIconLoaded" object:nil];
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[fetchedResultsController release];
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
 //   self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.tableView.rowHeight = 75;
	
	// this defines the back button leading BACK TO THIS controller
	UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc]
										  initWithTitle:@"Apps"
										  style:UIBarButtonItemStyleBordered
										  target:nil
										  action:nil];
	self.navigationItem.backBarButtonItem = backBarButtonItem;
	[backBarButtonItem release];
	
	
	// initial fetch
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)configureCell:(ApplicationCell *)cell atIndexPath:(NSIndexPath *)indexPath 
{
    Product *app = (Product *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	
	double royalties = [app.totalSummary.sumRoyalties doubleValue];
	
	NSLog(@"%@", app.totalSummary);
	
	cell.appTitleLabel.text = app.title;
	
	double royalties_converted = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:royalties fromCurrency:@"EUR"];
	if (royalties_converted)
	{
		cell.royaltiesLabel.text = [NSString stringWithFormat:@"%0@", [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:royalties_converted]];
	}
	else
	{
		cell.royaltiesLabel.text = @"free";
	}

	cell.totalUnitsLabel.text = [NSString stringWithFormat:@"%@ units", app.totalSummary.sumUnits];
	
	
	// show badge depending on number of new reviews
	NSInteger newReviews = [app.newReviewsCount intValue];
	
	if (newReviews)
	{
		cell.badge.text = [app.newReviewsCount description];
	}
	else 
	{
		cell.badge.text = nil;
	}
	
	// show disclosure indicator if there are reviews
	if ([app.reviews count])
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else 
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	// set icon
	UIImage *icon = [[CoreDatabase sharedInstance] iconImageForProduct:app];
	if (!icon)
	{
		icon = [UIImage placeholderImageWithSize:CGSizeMake(112, 112) CornerRadius:20];
		//icon = [UIImage placeholderImageWithSize:CGSizeMake(56, 56) CornerRadius:10];
	}
	cell.imageView.image = icon;
}

#pragma mark Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row%2)
	{
		// light
		cell.backgroundColor=[UIColor colorWithRed:173.0/256.0 green:173.0/256.0 blue:176.0/256.0 alpha:1.0];
	}
	else
	{
		// dark
		cell.backgroundColor=[UIColor colorWithRed:152.0/256.0 green:152.0/256.0 blue:156.0/256.0 alpha:1.0];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    ApplicationCell *cell = (id)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ApplicationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell.
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	Product *app = (Product *)[self.fetchedResultsController objectAtIndexPath:indexPath];

	ApplicationReviewsViewController *appReviews = [[[ApplicationReviewsViewController alloc] initWithProduct:app] autorelease];
	[self.navigationController pushViewController:appReviews animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}




#pragma mark -
#pragma mark Fetched results controller
- (NSManagedObjectContext *)managedObjectContext
{
	return [CoreDatabase sharedInstance].managedObjectContext;
}


- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	
	NSPredicate *filter = [NSPredicate predicateWithFormat:@"isInAppPurchase = NO"];
	[fetchRequest setPredicate:filter];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptorCompany = [[[NSSortDescriptor alloc] initWithKey:@"companyName" ascending:YES] autorelease];
    NSSortDescriptor *sortDescriptorRoyalties = [[[NSSortDescriptor alloc] initWithKey:@"totalSummary.sumRoyalties" ascending:NO] autorelease];
    NSSortDescriptor *sortDescriptorTitle = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptorCompany, sortDescriptorRoyalties, sortDescriptorTitle, nil] autorelease];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"companyName" cacheName:@"Company"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
     
    return fetchedResultsController;
}    


#pragma mark -
#pragma mark Fetched results controller delegate


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
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
      newIndexPath:(NSIndexPath *)newIndexPath {
    
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


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark Notifications
- (void)appIconLoaded:(NSNotification *)notification
{
	[self.tableView reloadData];
}

@synthesize fetchedResultsController;

@end

