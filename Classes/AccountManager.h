//
//  AccountManager.h
//  ASiST
//
//  Created by Oliver on 07.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Account;
@interface AccountManager : NSObject {
	NSMutableArray *accounts;

}

@property (nonatomic, readonly) NSMutableArray *accounts;

+ (AccountManager *) sharedAccountManager;

- (Account *) addAccountForService:(NSString*)aService user:(NSString *)aUser;
- (void) removeAccount:(Account *)accountToRemove;


@end
