//
//  AccountManager.m
//  ASiST
//
//  Created by Oliver on 07.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "AccountManager.h"
#import <Security/Security.h>
#import "GenericAccount.h"
#import "GenericAccount+MyAppSales.h"

@interface AccountManager ()

- (void) loadAllGenericAccounts;

@end





@implementation AccountManager

@synthesize accounts;

static const UInt8 kKeychainIdentifier[]    = "com.drobnik.asist.KeychainUI\0";


static AccountManager *_sharedInstance = nil;


+ (AccountManager *) sharedAccountManager
{
	if (!_sharedInstance)
	{
		_sharedInstance = [[AccountManager alloc] init];
	}
	
	return _sharedInstance;
}

- (id) init
{
	if ((self = [super init]))
	{
		[self loadAllGenericAccounts];
		
		// migrate old version primary account
		
		if ([accounts count]==1)
		{
			GenericAccount *singleAccount = [accounts objectAtIndex:0];
			if ([singleAccount.service isEqualToString:@"HomeDir"])
			{
				NSLog(@"Migrating old account %@ to new ITC Service", singleAccount.account);

				/*
				GenericAccount *newAccount = [[GenericAccount alloc] initWithService:@"iTunes Connect" user:singleAccount.account];
				newAccount.description = singleAccount.description;
				newAccount.label = singleAccount.label;
				newAccount.comment = singleAccount.account;
				newAccount.password = singleAccount.password;
				 */
				
				singleAccount.service = @"iTunes Connect";
				singleAccount.description = singleAccount.account;
			}
		}
	}
	
	return self;
}

- (void) dealloc
{
	[accounts release];
	[super dealloc];
}


/*
// this takes the result from an attributes query, queries for the data (= password) and adds it in readable format
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    // The assumption is that this method will be called with a properly populated dictionary
    // containing all the right key/value pairs for the UI element.
    
    // Remove the generic attribute which distinguishes this Keychain Item with this
    // application.
    // Create returning dictionary populated with the attributes.
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    // Add the proper search key and class attribute.
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [returnDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    
    // Acquire the password data from the attributes.
    NSData *passwordData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordData) == noErr)
    {
        // Remove the search, class, and identifier key/value, we don't need them anymore.
        [returnDictionary removeObjectForKey:(id)kSecReturnData];
        
        // Add the password to the dictionary.
        NSString *passwordString = [[[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] 
														   encoding:NSUTF8StringEncoding] autorelease];
        [returnDictionary setObject:passwordString forKey:(id)kSecValueData];
    }
    else
    {
        // Don't do anything if nothing is found.
		// NSAssert(NO, @"Serious error, nothing is found in the Keychain.\n");
		
		// no password in keychain
		
		// Remove the search, class, and identifier key/value, we don't need them anymore.
        [returnDictionary removeObjectForKey:(id)kSecReturnData];
    }
    
    [passwordData release];
    return returnDictionary;
}
*/
 
// this loads all generic accounts from the keychain
- (void) loadAllGenericAccounts
{
	accounts = [[NSMutableArray alloc] init];
	
	NSMutableDictionary *genericPasswordQuery;    // A placeholder for a generic Keychain Item query.
	genericPasswordQuery = [[[NSMutableDictionary alloc] init] autorelease];
	[genericPasswordQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	NSData *keychainType = [NSData dataWithBytes:kKeychainIdentifier length:strlen((const char *)kKeychainIdentifier)];
	[genericPasswordQuery setObject:keychainType forKey:(id)kSecAttrGeneric];
	
	// We want all generic accounts and all attributes
	[genericPasswordQuery setObject:(id)kSecMatchLimitAll forKey:(id)kSecMatchLimit];
	[genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
	[genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];  // so password is also returned

	
	NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:genericPasswordQuery];
	
	id result = nil;
	
	if (SecItemCopyMatching((CFDictionaryRef)tempQuery, (CFTypeRef *)&result) == noErr)
	{
		if ([result isKindOfClass:[NSDictionary class]])
		{
			NSDictionary *resultAsDictionary = (NSDictionary *)result;
			
			GenericAccount *tmpAcct = [[GenericAccount alloc] initFromKeychainDictionary:resultAsDictionary];
			[accounts addObject:tmpAcct];
			[tmpAcct release];
		}
		else if ([result isKindOfClass:[NSArray class]])
		{
			NSArray *resultsAsArray = (NSArray *)result;
			
			for (NSDictionary *oneAccount in resultsAsArray)
			{
				GenericAccount *tmpAcct = [[GenericAccount alloc] initFromKeychainDictionary:oneAccount];
				[accounts addObject:tmpAcct];
				[tmpAcct release];
			}
		}
	}
}




#pragma mark Adding/Removing Accounts


- (GenericAccount *) addAccountForService:(NSString*)aService user:(NSString *)aUser
{
	GenericAccount *tmpAccount = [[GenericAccount alloc] initService:aService forUser:aUser];
	
	[accounts addObject:tmpAccount];
	
	return [tmpAccount autorelease];
}

- (void) removeAccount:(GenericAccount *)accountToRemove
{
	[accountToRemove removeFromKeychain];
	[self.accounts removeObject:accountToRemove];
}

#pragma mark Retrieving Accounts
- (NSArray *)accountsOfType:(NSString *)type
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (GenericAccount *oneAccount in accounts)
	{
		if ([oneAccount.service isEqualToString:type])
		{
			[tmpArray addObject:oneAccount];
		}
	}
	
	if ([tmpArray count])
	{
		return [NSArray arrayWithArray:tmpArray];
	}
	else
	{
		return nil;
	}

}

@end
