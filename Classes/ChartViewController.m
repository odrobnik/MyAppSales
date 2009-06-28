//
//  ChartViewController.m
//  ASiST
//
//  Created by Oliver Drobnik on 20.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ChartViewController.h"
#import "ChartView.h"
#import "AxisView.h"
#import "LegendView.h"
#import "ASiSTAppDelegate.h"
#import "YahooFinance.h"
#import "BirneConnect.h"


@implementation ChartViewController

@synthesize myLegend, myAxis, myChart, myScroll;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (id)initWithChartData:(NSDictionary *)dataDict
{
	if (self = [super init])
	{
		UIView *rootView = [[UIView alloc] init];
		self.view = rootView;
		
		self.myChart = [[ChartView alloc] initWithChartData:dataDict];
		
		//ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		NSString *axis_type = [dataDict objectForKey:@"Axis"];
		
		CGRect axis_size = CGRectMake(0, 0, 30, 367);
		//AxisView *myAxis;
	
		if ([axis_type isEqualToString:@"Sum"])
		{
			double converted_max = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:myChart.max_chart_value fromCurrency:@"EUR"];
			self.myAxis = [[AxisView alloc] initWithFrame:axis_size max:converted_max currency:[[YahooFinance sharedInstance] mainCurrency]];
		}
		else
		{
			double maximum = [[dataDict objectForKey:@"Maximum"] doubleValue];
			self.myAxis = [[AxisView alloc] initWithFrame:axis_size max:maximum currency:@"Units"];
		}

		myAxis.opaque = NO;
		[rootView addSubview:myAxis];
		[myAxis release];
		
		CGRect legend_size = CGRectMake(0, 267.0, 320, 100.0);
		self.myLegend = [[LegendView alloc] initWithFrame:legend_size Data:dataDict];
		myAxis.bottom_inset = myLegend.required_height+10.0;
		myChart.bottom_inset =  myLegend.required_height+10.0;
		//		myLegend.frame = legend_size;
		//	myLegend.opaque = YES;
		myLegend.backgroundColor = [UIColor clearColor];
		[rootView insertSubview:myLegend aboveSubview:myAxis];
		[myLegend release];
		
		CGRect chart_size = [myChart chartDimensions];
		CGRect scroll_size = CGRectMake(0, 0, 320, 367);
		
		self.myScroll = [[UIScrollView alloc] initWithFrame:scroll_size];
		[rootView insertSubview:myScroll belowSubview:myAxis];
		[myScroll addSubview:myChart];
		[myScroll setContentSize:CGSizeMake(chart_size.size.width, chart_size.size.height)];
		myScroll.showsHorizontalScrollIndicator = YES;
		myScroll.delegate = self;
		
		myScroll.maximumZoomScale = 1;
		myScroll.maximumZoomScale = 1;
		[myChart release];
		
		// scroll to the very right
		chart_size.origin.x = chart_size.size.width - 320.0;
		[myScroll scrollRectToVisible:chart_size animated:NO];
	}
	return self;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return myChart;
}

/*
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	//NSLog(@"%f, %f", scrollView.contentSize.height,  scrollView.contentOffset.y);
	float scale = scrollView.contentSize.height / 367.0;
	
	myAxis.scale = scale;
	CGPoint tmpOffset = scrollView.contentOffset;
	tmpOffset.y = scrollView.contentSize.height - 367.0 - tmpOffset.y;
	myAxis.offset = tmpOffset;
	[myAxis setNeedsDisplay];
	
}
 */
 
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
//	NSLog(@"scale: %f", scale);
	CGRect contentSize = [myChart chartDimensions];
	CGSize newSize;
	newSize.width = contentSize.size.width * scale;
	newSize.height = contentSize.size.height * scale;
	myAxis.scale = scale;
	[myAxis setNeedsDisplay];
	
//	[myScroll setContentSize:newSize];
	
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
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


- (void)dealloc {
	[myChart release];
	[myAxis release];
	[myLegend release];
	[myScroll release];
    [super dealloc];
}


@end
