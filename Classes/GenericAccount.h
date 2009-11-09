//
//  GenericAccount.h
//  ASiST
//
//  Created by Oliver on 09.11.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GenericAccount : NSObject 
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


- (id) initFromKeychainDictionary:(NSDictionary *)dict;  // loads existing
- (id) initService:(NSString *)aService forUser:(NSString *)aUser; // creates new one
- (void)removeFromKeychain;


@property (nonatomic, retain) NSString *account;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *comment;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *service;
@property (nonatomic, retain) NSString *password;

@end
