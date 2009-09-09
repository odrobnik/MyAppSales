//
//  Account.m
//  ASiST
//
//  Created by Oliver on 07.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "Account.h"
#import <Security/Security.h>



@interface Account ()

- (NSMutableDictionary *)makeUniqueSearchQuery;  // mutable, if primary keys are updated
- (void)writeToKeychain;


@property(nonatomic, retain) NSString *pk_account;
@property(nonatomic, retain) NSString *pk_service;

@end





@implementation Account

@synthesize account, description, comment, label, service, password, pk_account, pk_service;

static const UInt8 kKeychainIdentifier[]    = "com.drobnik.asist.KeychainUI\0";

#pragma mark Init/dealloc	

- (id) initFromKeychainDictionary:(NSDictionary *)dict
{
	if (self = [super init])
	{
		account = [[dict objectForKey:(id)kSecAttrAccount] retain];
		description = [[dict objectForKey:(id)kSecAttrDescription] retain];
		comment = [[dict objectForKey:(id)kSecAttrComment] retain];
		label = [[dict objectForKey:(id)kSecAttrLabel] retain];
		service = [[dict objectForKey:(id)kSecAttrService] retain];
		

		
		// password is NSData, need to convert to string
		password = [[NSString alloc] initWithData:[dict objectForKey:(id)kSecValueData] encoding:NSUTF8StringEncoding];
		
		
		keychainData = [dict mutableCopy];
		
		// remember primary key 
		self.pk_account = account;
		self.pk_service = service;

		//uniqueSearchQuery = [[self makeUniqueSearchQuery] retain];

		[keychainData setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass]; 

		NSLog(@"keychain after load %@", keychainData);

		
		dirty = NO;
	}
	
	return self;
}


- (id) initWithService:(NSString *)aService user:(NSString *)aUser
{
	if (self = [super init])
	{
		account = [aUser retain];
		service = [aService retain];
		
		// remember primary key 
		self.pk_account = account;
		self.pk_service = service;
		
		keychainData = [[NSMutableDictionary dictionary] retain];
		
		[keychainData setObject:account forKey:(id)kSecAttrAccount];
		[keychainData setObject:service forKey:(id)kSecAttrService];
		
		[keychainData setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];

		NSData *keychainType = [NSData dataWithBytes:kKeychainIdentifier length:strlen((const char *)kKeychainIdentifier)];
		[keychainData setObject:keychainType forKey:(id)kSecAttrGeneric];
		
		[self writeToKeychain];
		
	}
	
	return self;
}


- (void) dealloc
{
	[keychainData release];
	[account release];
	[description release];
	[comment release];
	[label release];
	[service release];
	[password release];
	
	[pk_account release];
	[pk_service release];
	
	[super dealloc];
}	


#pragma mark Keychain Access 
// search query to find only this account on the keychain
- (NSMutableDictionary *)makeUniqueSearchQuery
{
	NSMutableDictionary *genericPasswordQuery = [[NSMutableDictionary alloc] init];
	[genericPasswordQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	NSData *keychainType = [NSData dataWithBytes:kKeychainIdentifier length:strlen((const char *)kKeychainIdentifier)];
	[genericPasswordQuery setObject:keychainType forKey:(id)kSecAttrGeneric];
	
	// Use the proper search constants, return only the attributes of the first match.
	[genericPasswordQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
	
	// also limit to current pk
	[genericPasswordQuery setObject:pk_account forKey:(id)kSecAttrAccount];
	[genericPasswordQuery setObject:pk_service forKey:(id)kSecAttrService];
	
	return genericPasswordQuery;
}

- (void)writeToKeychain
{
    NSDictionary *attributes = NULL;
    NSMutableDictionary *updateItem = NULL;
	NSDictionary *uniqueSearchQuery = [self makeUniqueSearchQuery];
	
    if (SecItemCopyMatching((CFDictionaryRef)uniqueSearchQuery, (CFTypeRef *)&attributes) == noErr)
    {
        // First we need the attributes from the Keychain.
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
 		
		// we copy the class, service and account as search values
        [updateItem setObject:[uniqueSearchQuery objectForKey:(id)kSecClass] forKey:(id)kSecClass];
		[updateItem setObject:pk_account forKey:(id)kSecAttrAccount];
		[updateItem setObject:pk_service forKey:(id)kSecAttrService];

        
        // Lastly, we need to set up the updated attribute list being careful to remove the class.
        NSMutableDictionary *tempCheck = [NSMutableDictionary  dictionaryWithDictionary:keychainData];
        [tempCheck removeObjectForKey:(id)kSecClass];
        
		/*
		 
		 update item: {
		 acct = one;
		 agrp = "6P2Z3HB85N.com.drobnik.MyAppSales";
		 class = genp;
		 gena = <636f6d2e 64726f62 6e696b2e 61736973 742e4b65 79636861 696e5549>;
		 svce = last3;
		 }
		 
		 keychain item: {
		 acct = one;
		 class = genp;
		 gena = <636f6d2e 64726f62 6e696b2e 61736973 742e4b65 79636861 696e5549>;
		 svce = last3;
		 }
		 
		 -----> update item has the agrp extra, without it the request fails
		 */
				
#ifdef TARGET_IPHONE_SIMULATOR
		// this causes the SecItemUpdate to crash because on simulator it's "test"
		[tempCheck removeObjectForKey:@"agrp"];
#endif
		
		//[tempCheck setObject:@"6P2Z3HB85N.com.drobnik.MyAppSales" forKey:@"agrp"];
		
        // An implicit assumption is that you can only update a single item at a time.
        NSAssert( SecItemUpdate((CFDictionaryRef)updateItem, (CFDictionaryRef)tempCheck) == noErr, 
                 @"Couldn't update the Keychain Item." );
		
		[pk_account release];
		[pk_service release];
		
		pk_account = [account retain];
		pk_service = [service retain];
		
    }
    else
    {
        // No previous item found, add the new one.
		
		/*
		 2009-09-08 09:30:51.197 MyAppSales[4461:207] keychain item: {
		 acct = one;
		 class = genp;
		 gena = <636f6d2e 64726f62 6e696b2e 61736973 742e4b65 79636861 696e5549>;
		 svce = last4;
		 }
		 
		 --> secitem is identical
		 
		 */
		
        NSAssert( SecItemAdd((CFDictionaryRef)keychainData, NULL) == noErr, 
                 @"Couldn't add the Keychain Item." );
    }
	
	dirty = NO;
}


- (void)removeFromKeychain
{
	OSStatus junk = noErr;
    if (!keychainData) 
    {
        keychainData = [[NSMutableDictionary alloc] init];
    }
    else if (keychainData)
    {
		/*
		 
		 secitem: {
		 acct = "oliver@drobnik.com";
		 agrp = "6P2Z3HB85N.com.drobnik.MyAppSales";
		 class = genp;
		 gena = <636f6d2e 64726f62 6e696b2e 61736973 742e4b65 79636861 696e5549>;
		 svce = "iTunes Connect4";
		 }
		
		 
		 keychain: {
		 acct = "oliver@drobnik.com";
		 agrp = "6P2Z3HB85N.com.drobnik.MyAppSales";
		 gena = <636f6d2e 64726f62 6e696b2e 61736973 742e4b65 79636861 696e5549>;
		 svce = "iTunes Connect4";
		 
		 ---> class missing causes delete to fail
		 
		 */
		
		[keychainData setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];  // without class this fails
		
		junk = SecItemDelete((CFDictionaryRef)keychainData);
        NSAssert( junk == noErr || junk == errSecItemNotFound, @"Problem deleting current dictionary." );
    }
}



- (void)setObject:(id)inObject forKey:(id)key 
{
    if (inObject == nil) return;
    id currentObject = [keychainData objectForKey:key];
    if (![currentObject isEqual:inObject])
    {
        [keychainData setObject:inObject forKey:key];
        [self writeToKeychain];
    }
}

#pragma mark Setters

- (void) setAccount:(NSString *)newAccount
{
	if (account != newAccount) 
	{
		[account release];
		account = [newAccount retain];
		
		[self setObject:account forKey:(id)kSecAttrAccount];
		
		// update unique search query as well because this is part of primary key
		//[uniqueSearchQuery setObject:newAccount forKey:(id)kSecAttrAccount];
		
		dirty = YES;
	}
}

- (void) setPassword:(NSString *)newPassword
{
	if (password != newPassword) 
	{
		[password release];
		password = [newPassword retain];
		
		// password is NSData in keychain, need to convert

		[self setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(id)kSecValueData];
		dirty = YES;
	}
}

- (void) setService:(NSString *)newService
{
	if (service != newService) 
	{
		[service release];
		service = [newService retain];
		
		[self setObject:service forKey:(id)kSecAttrService];
		
		// update unique search query as well because this is part of primary key
		//[uniqueSearchQuery setObject:newService forKey:(id)kSecAttrService];

		dirty = YES;
	}
}

- (void) setDescription:(NSString *)newDescription
{
	if (description != newDescription) 
	{
		[description release];
		description = [newDescription retain];
		
		[self setObject:description forKey:(id)kSecAttrDescription];
		dirty = YES;
	}
}

- (void) setLabel:(NSString *)newLabel
{
	if (label != newLabel) 
	{
		[label release];
		label = [newLabel retain];
		
		[self setObject:label forKey:(id)kSecAttrLabel];
		dirty = YES;
	}
}

- (void) setComment:(NSString *)newComment
{
	if (comment != newComment) 
	{
		[comment release];
		comment = [newComment retain];
		
		[self setObject:comment forKey:(id)kSecAttrComment];
		dirty = YES;
	}
}

@end
