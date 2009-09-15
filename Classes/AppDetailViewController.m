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

@implementation AppDetailViewController

@synthesize myApp;

- (id) initForApp:(App *)app
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:UITableViewStylePlain]) 
	{
		self.myApp = app;
		self.title = app.title;
   
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appReviewsUpdated:) name:@"AppReviewsUpdated" object:nil];

	}
    return self;
}

- (void)dealloc 
{
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
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [myApp.reviews count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ReviewCell";
    
    ReviewCell *cell = (ReviewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ReviewCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	Review *rowReview = [myApp.reviews objectAtIndex:indexPath.row];
	
	cell.reviewText.text = rowReview.review;
	cell.reviewTitle.text = rowReview.title;
	cell.reviewAuthor.text = rowReview.name;
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterShortStyle];
	
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
	Review *review = [myApp.reviews objectAtIndex:indexPath.row];
	
	UIFont *font = [UIFont systemFontOfSize:12];
	CGRect contentRect = self.tableView.bounds;
	CGSize constraint = CGSizeMake(contentRect.size.width - 20, 500);
	
	NSString *text;
	
	float height = 16.0f;
	
	text = review.review;

	
	CGSize size = [text sizeWithFont:font constrainedToSize:constraint];
	
	height += size.height;
	
	text = review.name;
	font = [UIFont boldSystemFontOfSize:12];
	size = [text sizeWithFont:font constrainedToSize:constraint];
	
	height += size.height;
	
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
			[self.tableView reloadData];
		}
	}
	
}


@end

