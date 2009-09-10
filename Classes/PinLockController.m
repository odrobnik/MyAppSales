//
//  PinLockController.m
//  ASiST
//
//  Created by Oliver on 10.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "PinLockController.h"

@interface PinLockController ()
- (void) switchToConfirm:(BOOL)animated;
@end



@implementation PinLockController

@synthesize delegate, pin;



- (id)initWithMode:(PinLockControllerMode)initMode 
{
    if (self = [super init]) 
	{
		mode = initMode;

		hiddenTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 130, 100, 20)];
		self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
		hiddenTextField.alpha = 0;
		hiddenTextField.keyboardType = UIKeyboardTypeNumberPad;
		hiddenTextField.delegate = self;
		[self.view addSubview:hiddenTextField];
		[hiddenTextField becomeFirstResponder];
		
		message = [[UILabel alloc] initWithFrame:CGRectMake(0,33, 320, 20)];
		message.text = @"Enter a passcode";
		message.font = [UIFont boldSystemFontOfSize:17.0];
		message.shadowColor = [UIColor whiteColor];
		message.shadowOffset = CGSizeMake(0, 1);
		message.opaque = NO;
		message.backgroundColor = [UIColor clearColor];
		message.textAlignment = UITextAlignmentCenter;
		message.textColor = [UIColor colorWithRed:59.0/255.0 green:65.0/255.0 blue:80.0/255.0 alpha:1.0];
		[self.view addSubview:message];

		
		message2 = [[UILabel alloc] initWithFrame:CGRectMake(0,33, 320, 20)];
		[self.view addSubview:message2];
		message2.transform = CGAffineTransformMakeTranslation(300, 0);  // out of screen
		
		message2.font = [UIFont boldSystemFontOfSize:17.0];
		message2.shadowColor = [UIColor whiteColor];
		message2.shadowOffset = CGSizeMake(0, 1);
		message2.opaque = NO;
		message2.backgroundColor = [UIColor clearColor];
		message2.textAlignment = UITextAlignmentCenter;
		message2.textColor = [UIColor colorWithRed:59.0/255.0 green:65.0/255.0 blue:80.0/255.0 alpha:1.0];

		subMessage = [[UILabel alloc] initWithFrame:CGRectMake(0,151, 320, 20)];
		subMessage.font = [UIFont systemFontOfSize:14.0];
		subMessage.shadowColor = [UIColor whiteColor];
		subMessage.shadowOffset = CGSizeMake(0, 1);
		subMessage.opaque = NO;
		subMessage.backgroundColor = [UIColor clearColor];
		subMessage.textAlignment = UITextAlignmentCenter;
		subMessage.textColor = [UIColor colorWithRed:59.0/255.0 green:65.0/255.0 blue:80.0/255.0 alpha:1.0];
		[self.view addSubview:subMessage];
		
		
		first = YES;
		
		
		NSMutableArray *tmpArray = [NSMutableArray array];
		NSMutableArray *tmpArray2 = [NSMutableArray array];
		
		for (int i=0;i<4;i++)
		{
			UIImage *freeImg = [UIImage imageNamed:@"Pin_Free.png"];
			UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(23+71*i, 74, 61, 53)];
			imgView.image = freeImg;
			[tmpArray addObject:imgView];
			[self.view addSubview:imgView];
			[imgView release];
			
			UIImageView *imgView2 = [[UIImageView alloc] initWithFrame:CGRectMake(23+71*i, 74, 61, 53)];
			imgView2.image = freeImg;
			imgView2.transform = CGAffineTransformMakeTranslation(300, 0);
			[tmpArray2 addObject:imgView2];
			[self.view addSubview:imgView2];
			[imgView2 release];
		}
		
		pins = [[NSArray alloc] initWithArray:tmpArray];
		pins2 = [[NSArray alloc] initWithArray:tmpArray2];
		
		
		if (mode == PinLockControllerModeSetPin)
		{
			self.title = @"Set Passcode";
			message2.text = @"Re-enter a passcode";
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
																								   target:self action:@selector(cancel:)];

			first = YES;

			
		}
		else if (mode == PinLockControllerModeRemovePin)
		{
			// nothing yet
			self.title = @"Turn off Passcode";
			message2.text = @"Enter your passcode";
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
																								   target:self action:@selector(cancel:)];

			[self switchToConfirm:NO];
		}
		else if (mode == PinLockControllerModeUnlock)
		{
			// nothing yet
			self.title = @"Unlock MyAppSales";
			message2.text = @"Enter your passcode";
			
			[self switchToConfirm:NO];
		}
	}
    return self;
}

- (void)dealloc {
	[pin release];
	[message release];
	[message2 release];
	[hiddenTextField release];
	[pins release];
	[pins2 release];
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


- (void) switchToFirst:(BOOL)animated
{
	if (animated)
		[UIView beginAnimations:nil context:nil];
	
	message.transform = CGAffineTransformIdentity;
	
	for (UIImageView *oneView in pins)
	{
		oneView.transform = CGAffineTransformIdentity;
		oneView.image = [UIImage imageNamed:@"Pin_Free.png"];
	}
	
	for (UIImageView *oneView in pins2)
	{
		oneView.transform = CGAffineTransformMakeTranslation(+300, 0);  // out of screen
		
	}
	message2.transform = CGAffineTransformMakeTranslation(+300, 0);  // out of screen
	
	if (animated)
		[UIView commitAnimations];
	
	first=YES;
	hiddenTextField.text = @"";
}

- (void) switchToConfirm:(BOOL)animated
{
	if (animated)
		[UIView beginAnimations:nil context:nil];
	
	message.transform = CGAffineTransformMakeTranslation(-300, 0);  // out of screen
	
	for (UIImageView *oneView in pins)
	{
		oneView.transform = CGAffineTransformMakeTranslation(-300, 0);
	}
	
	for (UIImageView *oneView in pins2)
	{
		oneView.transform = CGAffineTransformIdentity;
		oneView.image = [UIImage imageNamed:@"Pin_Free.png"];
	}
	message2.transform = CGAffineTransformIdentity;
	
	if (animated)
		[UIView commitAnimations];
	
	first=NO;
	hiddenTextField.text = @"";
}

#pragma mark hiddenTextField
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	
	NSInteger newLength = [textField.text length]-range.length+[string length];
	
	int i = newLength;
	
	NSArray *arrayToSet = first?pins:pins2;
	for (UIImageView *oneView in arrayToSet)
	{
		if (i>0)
		{
			oneView.image = [UIImage imageNamed:@"Pin_Set.png"];
			i--;
		}
		else
		{
			oneView.image = [UIImage imageNamed:@"Pin_Free.png"];
		}
	}
	
	
	// if all 4 set
	if (newLength==4)
	{
		// prettier: in any case we want the rightmost field set
		
		// we cannot come here via a backspace so we assume that textField + string = PIN entered
		NSMutableString *pinEntered = [NSMutableString stringWithString:textField.text];
		[pinEntered appendString:string];
		
		if (mode == PinLockControllerModeSetPin)
		{
			if (first)
			{
				self.pin = [NSString stringWithString:pinEntered];
				[self switchToConfirm:YES];
				return NO;
			}
			else 
			{
				if ([pinEntered isEqualToString:pin])
				{
					if (delegate && [delegate respondsToSelector:@selector(didFinishSelectingNewPin:)])
					{
						[delegate didFinishSelectingNewPin:[NSString stringWithString:pinEntered]];
					}
				}
				else
				{
					// 2nd pin does not match
					subMessage.text = @"Passcodes did not match. Try again.";
	
					[self switchToFirst:YES];
					return NO;
				}

			}
		}
		else if (mode == PinLockControllerModeRemovePin)
		{
			if ([pinEntered isEqualToString:pin])
			{
				if (delegate && [delegate respondsToSelector:@selector(didFinishRemovingPin)])
				{
					[delegate didFinishRemovingPin];
				}
			}
			else
			{
				// 2nd pin does not match
				[self performSelector:@selector(switchToConfirm:)  withObject:[NSNumber numberWithBool:NO] afterDelay:0.2]; 
//				[self switchToConfirm:NO];
				return NO;
			}
		}
		else if (mode == PinLockControllerModeUnlock)
		{
			if ([pinEntered isEqualToString:pin])
			{
				if (delegate && [delegate respondsToSelector:@selector(didFinishUnlocking)])
				{
					[delegate didFinishUnlocking];
				}
			}
			else
			{
				// 2nd pin does not match
				subMessage.text = @"Wrong Passcode. Try again.";
				
				[self performSelector:@selector(switchToConfirm:)  withObject:[NSNumber numberWithBool:NO] afterDelay:0.2]; 
				//[self switchToConfirm:NO];
				return NO;
			}
		}
	}
	
	return YES;
}






#pragma mark Actions

- (void) cancel:(id)sender
{
	[self.navigationController dismissModalViewControllerAnimated:YES];
}



@end

