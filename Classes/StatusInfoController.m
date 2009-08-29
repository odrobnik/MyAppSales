//
//  StatusInfoController.m
//  ASiST
//
//  Created by Oliver Drobnik on 30.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "StatusInfoController.h"


@implementation StatusInfoController

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement loadView to create a view hierarchy programmatically, without using a nib.
/*
- (void)loadView 
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	self.view.alpha = 0;   // start invisible
	myTimer = nil;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusMessage:) name:@"StatusMessage" object:nil];
}


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


- (void) showStatus:(BOOL)visible
{
	[UIView beginAnimations:nil context:NULL];
	if (visible)
	{
		[UIView setAnimationDuration:1.0];
		[self.view setAlpha:0.95];

	}
	else
	{
		[UIView setAnimationDuration:3.0];
		[self.view setAlpha:0];
	}
	
	[UIView commitAnimations];
}

- (void)statusMessage:(NSNotification *) notification
{
	NSString *msg = (NSString *)[notification userInfo];
	//NSLog(@"statusMessage: %@", msg);

	// in any case we cancel the timeout if it is running
	
	if (myTimer)
	{
		[myTimer invalidate];
		myTimer = nil;
	}
	
	
	if (msg)
	{
		statusLabel.text = msg;
		[statusLabel setNeedsDisplay];
		[self showStatus:YES];
		myTimer = [NSTimer scheduledTimerWithTimeInterval: 30.0
												   target: self
												 selector: @selector(statusExpired:)
												 userInfo: nil
												  repeats: NO];
		

	}
	else
	{
		// no message = hide
		[self showStatus:NO];
	}
}

- (void) statusExpired:(id)sender
{
	[self showStatus:NO];
	myTimer = nil;
}

- (void)dealloc {
	// Remove notification observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [super dealloc];
}


@end
