//
//  AccountManager.h
//  ASiST
//
//  Created by Oliver on 07.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GenericAccount.h"
#import "GenericAccount+MyAppSales.h"

@interface AccountManager : NSObject {
	NSMutableArray *accounts;

}

@property (nonatomic, readonly) NSMutableArray *accounts;

+ (AccountManager *) sharedAccountManager;

- (GenericAccount *) addAccountForService:(NSString*)aService user:(NSString *)aUser;
- (void) removeAccount:(GenericAccount *)accountToRemove;

- (NSArray *)accountsOfType:(NSString *)type;

@end
