//
//  PinLockController.h
//  ASiST
//
//  Created by Oliver on 10.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum { PinLockControllerModeSetPin = 0, PinLockControllerModeChangePin = 1, PinLockControllerModeRemovePin = 2, PinLockControllerModeUnlock = 3} PinLockControllerMode;



@protocol PinLockDelegate <NSObject>

@optional

- (void) didFinishSelectingNewPin:(NSString *)newPin;
- (void) didFinishRemovingPin;
- (void) didFinishUnlocking;

@end



@interface PinLockController : UIViewController <UITextFieldDelegate> {
	PinLockControllerMode mode;
	NSArray *pins;
	NSArray *pins2;
	
	UITextField *hiddenTextField;
	UILabel *message;
	UILabel *message2;
	
	UILabel *subMessage;
	
	UINavigationBar *navBar;
	
	BOOL first;
	
	NSString *pin;
	
	id <PinLockDelegate> delegate;
}

@property (nonatomic, assign) id <PinLockDelegate> delegate;
@property (nonatomic, retain) NSString *pin;

- (id)initWithMode:(PinLockControllerMode)initMode;

@end
