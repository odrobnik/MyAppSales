//
//  StatusInfoController.m
//  ASiST
//
//  Created by Oliver Drobnik on 30.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "StatusInfoController.h"


@implementation StatusInfoController

@synthesize backgroundView;

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
	NSString *msg;
	NSInteger type=0;  // standard is only status
	
	id userInfo = [notification userInfo];
	
	if ([userInfo isKindOfClass:[NSString class]])
	{
		msg = (NSString *)[notification userInfo];
		type = 0;
	}
	else if ([userInfo isKindOfClass:[NSDictionary class]])
	{
			msg = [userInfo objectForKey:@"message"];
		if ([[userInfo objectForKey:@"type"] isEqualToString:@"Error"])
		{
			type = 1;
		}
		else if ([[userInfo objectForKey:@"type"] isEqualToString:@"Success"])
		{
			type = 2;
		}
	}
	else {
		msg = nil;
	}

	
	if (myTimer)
	{
		[myTimer invalidate];
		myTimer = nil;
	}
	
	
	if (msg)
	{
		if (type==0)
		{
			backgroundView.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:102.0/255.0 alpha:1.0];
		}
		else if (type==1)
		{
			backgroundView.backgroundColor = [UIColor colorWithRed:251.0/255.0 green:81.0/255.0 blue:84.0/255.0 alpha:1.0];
		}
		else if (type==2)
		{
			backgroundView.backgroundColor = [UIColor colorWithRed:81.0/255.0 green:251.0/255.0 blue:84.0/255.0 alpha:1.0];
		}
		
		
		statusLabel.text = msg;
		[statusLabel setNeedsDisplay];
		[self showStatus:YES];
		myTimer = [NSTimer scheduledTimerWithTimeInterval: (type==0)?30.0:3.0
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
