//
//  StatusInfoController.h
//  ASiST
//
//  Created by Oliver Drobnik on 30.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface StatusInfoController : UIViewController {
	IBOutlet UILabel *statusLabel;
	UIView *backgroundView;
	
	NSTimer *myTimer;
}

@property (nonatomic, retain) IBOutlet UIView *backgroundView;

- (void) showStatus:(BOOL)visible;

@end
