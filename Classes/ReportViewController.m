//
//  ReportViewController.m
//  ASiST
//
//  Created by Oliver Drobnik on 26.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "ReportViewController.h"
#import "ASiSTAppDelegate.h"
#import "Report_v1.h"
#import "Database.h"
//#import "GenericReportController.h"
#import "ReportAppsController.h"

#import "CalendarDayView.h"
#import "DayReportCell.h"

#import "YahooFinance.h"


@interface ReportViewController ()

- (void) createIndex;

@end



@implementation ReportViewController


@synthesize report_array, tabBarItem;



- (id)initWithReportArray:(NSArray *)array reportType:(ReportType)type style:(UITableViewStyle)style 
{
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
		self.report_array = [NSMutableArray arrayWithArray:array];  // make it mutable for insertions
		report_type = type;
		
		switch (report_type) {
			case ReportTypeDay:
			{
				self.title = @"Days";
				break;
			}	
			case ReportTypeWeek:
			{
				self.title = @"Weeks";
				break;
			}
			case ReportTypeFree:
			{
				self.title = @"Months (Free)";
				// this defines the back button leading BACK TO THIS controller
				UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc]
													  initWithTitle:@"Months"
													  style:UIBarButtonItemStyleBordered
													  target:nil
													  action:nil];
				self.navigationItem.backBarButtonItem = backBarButtonItem;
				[backBarButtonItem release];
				break;
			}
			case ReportTypeFinancial:
			{
				self.title = @"Months (Financial)";
				// this defines the back button leading BACK TO THIS controller
				UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc]
													  initWithTitle:@"Months"
													  style:UIBarButtonItemStyleBordered
													  target:nil
													  action:nil];
				self.navigationItem.backBarButtonItem = backBarButtonItem;
				[backBarButtonItem release];
				break;
			}
			default:
				break;
		}
		
		self.tabBarItem = self.parentViewController.tabBarItem;
		self.tableView.rowHeight = 45.0;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newReportNotification:) name:@"NewReportAdded" object:nil];
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newReportNotification:) name:@"NewReportRead" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainCurrencyNotification:) name:@"MainCurrencyChanged" object:nil];

		
		[self createIndex];
    }
    return self;
}


- (void)dealloc {
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[indexByYearMonthSortedKeys release];
	[indexByYearMonth release];
	[tabBarItem release];
    [super dealloc];
}



 - (void)viewWillAppear:(BOOL)animated {
 [super viewWillAppear:animated];
	 [self.tableView reloadData];
 }
 

 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 
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

#pragma mark Notifications

- (void)mainCurrencyNotification:(NSNotification *)notification
{
	[self.tableView reloadData];
}

// new Reports cause insertion animation
- (void)newReportNotification:(NSNotification *) notification
{
	if(notification)
	{
		NSDictionary *tmpDict = [notification userInfo];
		Report_v1 *report = [tmpDict objectForKey:@"Report"];
		
		if (report.reportType == report_type)
		{	
			if ((report_type == ReportTypeWeek) ||(report_type == ReportTypeFinancial)||(report_type == ReportTypeFree))
			{
				NSInteger insertionIndex = [[tmpDict objectForKey:@"InsertionIndex"] intValue];
				
				[report_array insertObject:report atIndex:insertionIndex];
				
				NSIndexPath *tmpIndex = [NSIndexPath indexPathForRow:insertionIndex inSection:0];
				NSArray *insertIndexPaths = [NSArray arrayWithObjects:
											 tmpIndex,
											 nil];
				
				[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
			}
			else
			{
				// for days we have multiple sections = months
				
				// first find the correct month
				NSCalendar *gregorian = [[[NSCalendar alloc]
										  initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
				
				
				NSDateComponents *dayComps = [gregorian components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:report.fromDate];
				
				NSString *yearMonthKey = [NSString stringWithFormat:@"%04d-%02d", [dayComps year], [dayComps month]];
				
				NSMutableArray *monthArray = [indexByYearMonth objectForKey:yearMonthKey];
				
				if (!monthArray)
				{
					// need to add this month, this means we also need to insert a new section
					monthArray = [NSMutableArray array];
					[indexByYearMonth setObject:monthArray forKey:yearMonthKey];
					
					[monthArray addObject:report];  // first one, index will be 0
					
					// redo the index
					[indexByYearMonthSortedKeys release];
					NSArray *keys = [indexByYearMonth allKeys];
					indexByYearMonthSortedKeys = [[keys sortedArrayUsingSelector:@selector(compareDesc:)] retain];
					
					NSUInteger newSectionIdx = [indexByYearMonthSortedKeys indexOfObject:yearMonthKey];
					
					[self.tableView insertSections:[NSIndexSet indexSetWithIndex:newSectionIdx] withRowAnimation:UITableViewRowAnimationRight];
					
					// not necessary to animate row as well as the section insert also animates the row insertion
					
				}
				else
				{
					// month already exists
					NSUInteger insertSectionIdx = [indexByYearMonthSortedKeys indexOfObject:yearMonthKey];
					
					// find index to insert to
					
					NSEnumerator *enu = [monthArray objectEnumerator];
					Report_v1 *oneReport;
					NSUInteger reportIdx = 0;
					
					while ((oneReport = [enu nextObject])&&([report compareByReportDateDesc:oneReport]==NSOrderedDescending)) {
						reportIdx++;
					}
					
					
					//[monthArray addObject:oneReport];
					[monthArray insertObject:report atIndex:reportIdx];
					
					NSArray *insertIndexPaths = [NSArray arrayWithObjects:
												 [NSIndexPath indexPathForRow:reportIdx inSection:insertSectionIdx],
												 nil];
					
					[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
				}
				
			}
			
			
			
		}
		
	}
}

// new Reports cause update of badges
- (void)newReportRead:(NSNotification *) notification
{
	//[self.tableView reloadData];  // to change icon where there are new reports
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	report_icon = [[UIImage imageNamed:@"Report_Icon.png"] retain];
	report_icon_new = [[UIImage imageNamed:@"Report_Icon_New.png"] retain];
	
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if (report_type==0)
	{
		int ret = [indexByYearMonthSortedKeys count];
		if (ret)
		{
			return ret;
		}
		else
		{
			return 1;  // must have at least one section or else crash
		}
	}
	
	return 1;   // only one report type here
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ((report_type==0)&&(section<[indexByYearMonthSortedKeys count]))  // 1 section even though it's empty
	{
		NSString *key = [indexByYearMonthSortedKeys objectAtIndex:section];
		NSArray *monthArray = [indexByYearMonth objectForKey:key];
		
		Report_v1 *tmpReport = [monthArray objectAtIndex:0];
		
		
		NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormat setDateFormat:@"MMMM yyyy"];
		
		return [dateFormat stringFromDate:tmpReport.fromDate];
	}
	
	return nil;
}

// The accessory type is the image displayed on the far right of each table cell. In order for the delegate method
// tableView:accessoryButtonClickedForRowWithIndexPath: to be called, you must return the "Detail Disclosure Button" type.
/*
- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellAccessoryDisclosureIndicator;
}*/

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	/*
	 ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	 // section = report_type_id
	 NSMutableArray *tmpArray = [[appDelegate.itts reportsByType] objectAtIndex:section];
	 
	 return [tmpArray count];
	 */
	
	if (report_type==0)
	{
		
		if (section>=[indexByYearMonthSortedKeys count])
		{
			// we have one virtual section to prevent crash
			return 0;
		}
			
		NSString *key = [indexByYearMonthSortedKeys objectAtIndex:section];
		NSArray *monthArray = [indexByYearMonth objectForKey:key];
		
		return [monthArray count];
	}
	
	return [report_array count];
	
}

/*
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	Report *tmpReport;
	
	if (report_type==ReportTypeDay)
	{
		NSString *key = [indexByYearMonthSortedKeys objectAtIndex:indexPath.section];
		NSArray *monthArray = [indexByYearMonth objectForKey:key];
		
		tmpReport = [monthArray objectAtIndex:indexPath.row];
	}
	else
	{
		tmpReport = [report_array objectAtIndex:indexPath.row];
	}
	
	if (tmpReport.isNew)
	{
		cell.CELL_IMAGE = report_icon_new;
	}
	else
	{
		cell.CELL_IMAGE = report_icon;
	}
}
*/
 
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    
	Report_v1 *tmpReport;
	
	if (report_type==99)  // disabled
	{
		DayReportCell *cell = (DayReportCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[DayReportCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		}
		
		NSString *key = [indexByYearMonthSortedKeys objectAtIndex:indexPath.section];
		NSArray *monthArray = [indexByYearMonth objectForKey:key];
		
		tmpReport = [monthArray objectAtIndex:indexPath.row];
		cell.dayView.date = tmpReport.fromDate;
		
		double convertedRoyalties = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:[tmpReport sumRoyaltiesEarned] fromCurrency:@"EUR"];
		cell.royaltyEarnedLabel.text = [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:convertedRoyalties];
	
		
		cell.unitsSoldLabel.text = [NSString stringWithFormat:@"%d / %d", [tmpReport sumUnitsSold], [tmpReport sumUnitsFree]];
		//cell.dayLabel.text = [NSString stringWithFormat:@"%d", [tmpReport day]];
		
		/*
		if (tmpReport.isNew)
		{
			cell.iconImage.image = report_icon_new;
		}
		else
		{
			cell.iconImage.image = report_icon;
		} 
		*/
		
		cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
	else
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		}
		
		if (report_type==ReportTypeDay)
		{
			NSString *key = [indexByYearMonthSortedKeys objectAtIndex:indexPath.section];
			NSArray *monthArray = [indexByYearMonth objectForKey:key];
			
			tmpReport = [monthArray objectAtIndex:indexPath.row];
		}
		else
		{
			tmpReport = [report_array objectAtIndex:indexPath.row];
		}
		
		cell.CELL_LABEL = [tmpReport listDescriptionShorter:NO];
		if (tmpReport.isNew)
		{
			cell.CELL_IMAGE = report_icon_new;
		}
		else
		{
			cell.CELL_IMAGE = report_icon;
		}
		
		cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;

		return cell;
	}
}


/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
 {
 switch (section) {
 case ReportTypeDay:
 return @"Days";
 break;
 case ReportTypeWeek:
 return @"Weeks";
 break;
 default:
 break;
 }
 return nil;
 }
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	Report_v1 *tmpReport;
	
	if (report_type==ReportTypeDay)
	{
		NSString *key = [indexByYearMonthSortedKeys objectAtIndex:indexPath.section];
		NSArray *monthArray = [indexByYearMonth objectForKey:key];
		
		tmpReport = [monthArray objectAtIndex:indexPath.row];
	}
	else
	{
		tmpReport = [report_array objectAtIndex:indexPath.row];
	}

	ReportAppsController *reportAppsController = [[ReportAppsController alloc] initWithReport:tmpReport];
	[self.navigationController pushViewController:reportAppsController animated:YES];
	[reportAppsController release];
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

#pragma mark Utility
- (void) createIndex
{
	[indexByYearMonth release];
	[indexByYearMonthSortedKeys release];
	
	indexByYearMonth = [[NSMutableDictionary alloc] init];
	
	
	NSCalendar *gregorian = [[[NSCalendar alloc]
							  initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	
	
	for (Report_v1 *oneReport in report_array)
	{
		// sort it into the correct month
		NSDateComponents *dayComps = [gregorian components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:oneReport.fromDate];
		
		NSString *yearMonthKey = [NSString stringWithFormat:@"%04d-%02d", [dayComps year], [dayComps month]];
		
		NSMutableArray *monthArray = [indexByYearMonth objectForKey:yearMonthKey];
		
		if (!monthArray)
		{
			// need to add this month
			monthArray = [NSMutableArray array];
			[indexByYearMonth setObject:monthArray forKey:yearMonthKey];
		}
		
		// add this report into the found/created month
		[monthArray addObject:oneReport];
	}
	
	
	// now sort the months into a new array
	
	NSArray *keys = [indexByYearMonth allKeys];
	indexByYearMonthSortedKeys = [[keys sortedArrayUsingSelector:@selector(compareDesc:)] retain];
	
	NSLog(@"%@", indexByYearMonth);
}


#pragma mark Direct Navigation

- (void)gotoReport:(Report_v1 *)reportToShow
{
	ReportAppsController *reportAppsController = [[ReportAppsController alloc] initWithReport:reportToShow];
	[self.navigationController pushViewController:reportAppsController animated:YES];
	[reportAppsController release];
}

@end

