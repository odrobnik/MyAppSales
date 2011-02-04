//
//  ApplicationReviewsViewController.m
//  ASiST
//
//  Created by Oliver on 27.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "ApplicationReviewsViewController.h"
#import "ReviewCell.h"
#import "Review.h"
#import "Product+Custom.h"

@implementation ApplicationReviewsViewController


- (id)initWithProduct:(Product *)product 
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:UITableViewStylePlain])) 
	{
		self.product = product;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(countryFlagLoaded:) name:@"CountryFlagLoaded" object:nil];
    }
    return self;
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_product release];
	[fetchedResultsController release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = _product.title;
	
	UIBarButtonItem *forwardButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(forwardReviews:)];
	self.navigationItem.rightBarButtonItem = forwardButtonItem;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchingDone:) name:@"AllDownloadsFinished" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchingStarted:) name:@"SynchingStarted" object:nil];
	
	
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



- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	refreshHeaderView.lastUpdatedDate = _product.lastReviewRefresh;
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

- (void)configureCell:(ReviewCell *)cell atIndexPath:(NSIndexPath *)indexPath 
{
    Review *review = (Review *)[self.fetchedResultsController objectAtIndexPath:indexPath];

	if (review.textTranslated)
	{
		cell.reviewText.text = review.textTranslated;
	}
	else
	{
		cell.reviewText.text = review.text;
	}
	
	cell.reviewTitle.text = review.title;
	cell.reviewAuthor.text = review.userName;
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterMediumStyle];
	
	if ([review.isNew boolValue])
	{
		cell.reviewTitle.textColor = [UIColor redColor];
	}
	else 
	{
		cell.reviewTitle.textColor = [UIColor whiteColor];
	}
	
	
	
	NSString *dateString = [df stringFromDate:review.date];
	cell.reviewDate.text = dateString;
	
	cell.reviewVersion.text = review.appVersion;
	cell.countryImage.image = [[CoreDatabase sharedInstance] flagImageForCountry:review.country];
	
	int stars = ([review.ratingPercent doubleValue] * 5.0);
	
	switch(stars)
	{
		case 5:
			[cell.ratingImage setImage: [UIImage imageNamed:@"5stars_16.png"]];
			break;
			
		case 4:
			[cell.ratingImage setImage: [UIImage imageNamed:@"4stars_16.png"]];
			break;
			
		case 3:
			[cell.ratingImage setImage: [UIImage imageNamed:@"3stars_16.png"]];
			break;
			
		case 2:
			[cell.ratingImage setImage: [UIImage imageNamed:@"2stars_16.png"]];
			break;
			
		case 1:
			[cell.ratingImage setImage: [UIImage imageNamed:@"1star_16.png"]];
			break;
			
		default:
			break;
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return [[self.fetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo name];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	Review *review = (Review *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	
	UIFont *font = [UIFont systemFontOfSize:12];
	CGRect contentRect = self.tableView.bounds;
	CGSize constraint = CGSizeMake(contentRect.size.width - 20, 500);
	
	NSString *text;
	
	float height = 16.0f;
	
	//text = review.review;
	
	if (review.textTranslated)
	{
		text = review.textTranslated;
	}
	else
	{
		text = review.text;
	}
	
	
	CGSize size = [text sizeWithFont:font constrainedToSize:constraint];
	
	height += size.height;
	
	text = review.userName;
	font = [UIFont boldSystemFontOfSize:12];
	size = [text sizeWithFont:font constrainedToSize:constraint];
	
	height += size.height;
	
	
	constraint = CGSizeMake(contentRect.size.width - 50, 500);
	text = review.title;
	font = [UIFont boldSystemFontOfSize:14];
	size = [text sizeWithFont:font constrainedToSize:constraint];
	
	height += size.height;
	
	return height + 32.0f;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    ReviewCell *cell = (id)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ReviewCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	
	NSPredicate *filter = [NSPredicate predicateWithFormat:@"app == %@", self.product];
	[fetchRequest setPredicate:filter];
	
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptorVersion = [[[NSSortDescriptor alloc] initWithKey:@"appVersion" ascending:NO] autorelease];
    NSSortDescriptor *sortDescriptorDate = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptorVersion, sortDescriptorDate, nil] autorelease];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"appVersion" cacheName:nil];
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
- (void)countryFlagLoaded:(NSNotification *)notification
{
	[self.tableView reloadData];
}

#pragma mark Reloading

- (void) reloadTableViewDataSource
{
	[_product getAllReviews];
}

- (void)synchingStarted:(NSNotification *)notification
{
}

- (void)synchingDone:(NSNotification *)notification
{
	refreshHeaderView.lastUpdatedDate = _product.lastReviewRefresh;
	[super dataSourceDidFinishLoadingNewData];
}

#pragma mark Forwarding Reviews
- (BOOL) hasMailAndCanSendWithIt
{
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if (mailClass != nil)
	{
		// We must always check whether the current device is configured for sending emails
		if ([mailClass canSendMail])
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
	else
	{
		return NO;
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[self dismissModalViewControllerAnimated:YES];
}

-(void)displayComposerSheetTo:(NSString*)toString subject:(NSString *)subject body:(NSString *)body

{
	MFMailComposeViewController *mailView = [[[MFMailComposeViewController alloc] init] autorelease];
	//NSString *reportHTML = [NSString stringWithFormat:NSLocalizedString(@"EMAILTEXT", @"HTML"), dateOfSwitch.text, (int)clock.fromHour, (int)clock.toHour, hint.text];
	
	
	if (body)
	{
		[mailView setMessageBody:body isHTML:YES];
	}
	
	if (toString)
	{
		[mailView setToRecipients:[NSArray arrayWithObject:toString]];
	}
	
	if (subject)
	{
		[mailView setSubject:subject];
	}
	
	[mailView.navigationBar setBarStyle:UIBarStyleBlackOpaque];
	mailView.mailComposeDelegate = (id)self;
	
	[self presentModalViewController:mailView animated:YES];
}

- (void)forwardReviews:(id)sender
{
	if ([self hasMailAndCanSendWithIt])
	{
		NSString *reviewHTML = [_product reviewsAsHTML];
		NSString *subject = [NSString stringWithFormat:@"Reviews for %@", _product.title];
		
		[self displayComposerSheetTo:nil subject:subject body:reviewHTML];
	}
}

@synthesize product = _product;
@synthesize fetchedResultsController;

@end

