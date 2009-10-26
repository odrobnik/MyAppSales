//
//  Account.h
//  ASiST
//
//  Created by Oliver on 07.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Account : NSObject 
{
	NSString *account;
	NSString *description;
	NSString *comment;
	NSString *label;
	NSString *service;
	NSString *password;
	
	NSMutableDictionary *keychainData;
	
	BOOL dirty;
	
	
	NSString *pk_account;
	NSString *pk_service;
}

@property (nonatomic, retain) NSString *account;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *comment;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *service;
@property (nonatomic, retain) NSString *password;



- (id) initFromKeychainDictionary:(NSDictionary *)dict;  // loads existing
- (id) initWithService:(NSString *)aService user:(NSString *)aUser;  // creates new one

- (void)removeFromKeychain;

@end
