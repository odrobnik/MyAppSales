//
//  AppDetailViewController.m
//  ASiST
//
//  Created by Oliver on 13.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "AppDetailViewController.h"
#import "App.h"
#import "Review.h"
#import "Country.h"
#import "ReviewCell.h"
#import "SynchingManager.h"

@interface AppDetailViewController ()

- (BOOL) hasMailAndCanSendWithIt;

@end



@implementation AppDetailViewController

@synthesize myApp;


- (void)loadReviews
{
	NSArray *unsorted = [myApp reviewsInStages:YES];
	[sortedReviews release];
	sortedReviews = [[unsorted sortedArrayUsingSelector:@selector(compareByReviewDate:)] retain];
	
	forwardButtonItem.enabled = [self hasMailAndCanSendWithIt]&&[sortedReviews count];
}


- (id) initForApp:(App *)app
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:UITableViewStylePlain]) 
	{
		self.myApp = app;
		self.title = app.title;
   
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appReviewsUpdated:) name:@"AppReviewsUpdated" object:nil];
		
		//UIBarButtonItem *left = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
		//UIBarButtonItem *middle = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
		//UIBarButtonItem *right = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
		
		forwardButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(forwardReviews:)];
		//reloadButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadReviews:)];
		
		//[self setToolbarItems:[NSArray arrayWithObjects:left, forwardButtonItem, middle, reloadButtonItem, right, nil] animated:YES];
		
		
		//reloadButtonItem.enabled = ![[SynchingManager sharedInstance] hasActiveOperations];
		self.navigationItem.rightBarButtonItem = forwardButtonItem;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchingDone:) name:@"AllDownloadsFinished" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchingStarted:) name:@"SynchingStarted" object:nil];
		
		[self loadReviews];
	}
    return self;
}

- (void)dealloc 
{
	[reloadButtonItem release];
	[forwardButtonItem release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[myApp release];
    [super dealloc];
}


/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/


- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	NSInteger reviewDownloadOpsForThisApp = 0;
	NSArray *reviewOps = [[SynchingManager sharedInstance] queuedOperationsOfClass:[ReviewDownloaderOperation class]];
	
	for (ReviewDownloaderOperation *oneOp in reviewOps)
	{
		if (oneOp.app == myApp)
		{
			reviewDownloadOpsForThisApp ++;
		}
	}

	if (reviewDownloadOpsForThisApp)
	{
		[self showReloadAnimationAnimated:NO];
	}
	
	refreshHeaderView.lastUpdatedDate = myApp.lastReviewRefresh;
	
	//[self.navigationController setToolbarHidden:NO animated:YES];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	//[self.navigationController setToolbarHidden:YES animated:YES];
}

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
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sortedReviews count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ReviewCell";
    
    ReviewCell *cell = (ReviewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ReviewCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	Review *rowReview = [sortedReviews objectAtIndex:indexPath.row];
	
	if (rowReview.translated_review)
	{
		cell.reviewText.text = rowReview.translated_review;
	}
	else
	{
		cell.reviewText.text = rowReview.review;
	}

	cell.reviewTitle.text = rowReview.title;
	cell.reviewAuthor.text = rowReview.name;
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterMediumStyle];
	
	if (rowReview.isNew)
	{
		cell.reviewTitle.textColor = [UIColor redColor];
	}
	else 
	{
		cell.reviewTitle.textColor = [UIColor whiteColor];
	}

	
	
	NSString *dateString = [df stringFromDate:rowReview.date];
	cell.reviewDate.text = dateString;
	
	cell.reviewVersion.text = rowReview.version;
	cell.countryImage.image = rowReview.country.iconImage;
	
	int stars = rowReview.stars*5.0;
	
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
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	Review *review = [sortedReviews objectAtIndex:indexPath.row];
	
	UIFont *font = [UIFont systemFontOfSize:12];
	CGRect contentRect = self.tableView.bounds;
	CGSize constraint = CGSizeMake(contentRect.size.width - 20, 500);
	
	NSString *text;
	
	float height = 16.0f;
	
	//text = review.review;
	
	if (review.translated_review)
	{
		text = review.translated_review;
	}
	else
	{
		text = review.review;
	}

	
	CGSize size = [text sizeWithFont:font constrainedToSize:constraint];
	
	height += size.height;
	
	text = review.name;
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


#pragma mark Notifications
- (void)appReviewsUpdated:(NSNotification *) notification
{
	if (notification)
	{
		App *changedApp = (App *)[notification userInfo];
		
		if (changedApp == myApp)
		{
			[self loadReviews];
			[self.tableView reloadData];
		}
	}
	
}

#pragma mark Actions
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
	mailView.mailComposeDelegate = self;
	
	[self presentModalViewController:mailView animated:YES];
}

- (void)forwardReviews:(id)sender
{
	if ([self hasMailAndCanSendWithIt])
	{
		NSString *reviewHTML = [myApp reviewsAsHTML];
		NSString *subject = [NSString stringWithFormat:@"Reviews for %@", myApp.title];
		
		[self displayComposerSheetTo:nil subject:subject body:reviewHTML];
	}
}

- (void)synchingStarted:(NSNotification *)notification
{
	[reloadButtonItem setEnabled:NO];
}

- (void)synchingDone:(NSNotification *)notification
{
	[reloadButtonItem setEnabled:YES];
	
	refreshHeaderView.lastUpdatedDate = myApp.lastReviewRefresh;
	[super dataSourceDidFinishLoadingNewData];
}

- (void)reloadReviews:(id)sender
{
	[reloadButtonItem setEnabled:NO];
	[myApp getAllReviews];
}

#pragma mark EGOTableViewPullRefresh

- (void)reloadTableViewDataSource
{
	[myApp getAllReviews];
}

@end

