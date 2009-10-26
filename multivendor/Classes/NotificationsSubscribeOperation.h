//
//  NotificationsSubscribeOperation.h
//  ASiST
//
//  Created by Oliver on 25.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Account;

@interface NotificationsSubscribeOperation : NSOperation 
{
		Account *account;
		
		NSObject *delegate;
		
		BOOL workInProgress;
	
	BOOL subscribeMode;
	}
	
	@property (nonatomic, assign) NSObject *delegate;
	
	
- (id) initForAccount:(Account *)notificationsAccount subscribe:(BOOL)doSubscribe;
	
	// status utility
	- (void) sendFinishToDelegate;
	- (void) setStatus:(NSString *)message;
	- (void) setStatusError:(NSString *)message;
	- (void) setStatusSuccess:(NSString *)message;
	
	@end
