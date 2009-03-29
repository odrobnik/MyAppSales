//
//  StatusInfoController.h
//  ASiST
//
//  Created by Oliver Drobnik on 30.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface StatusInfoController : UIViewController {
	IBOutlet UILabel *statusLabel;
	UIView *backgroundView;
	
	NSTimer *myTimer;
}

- (void) showStatus:(BOOL)visible;

@end
