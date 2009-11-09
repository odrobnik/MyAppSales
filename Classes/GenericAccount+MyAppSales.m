//
//  Account+MyAppSales.m
//  ASiST
//
//  Created by Oliver on 24.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "GenericAccount.h"
#import "GenericAccount+MyAppSales.h"
#import "Database.h"
#import "AppGrouping.h"

@implementation GenericAccount (MyAppSales)


- (void) setAppGrouping:(AppGrouping *)newAppGrouping
{
	self.label = [NSString stringWithFormat:@"%d", newAppGrouping.primaryKey];
}

- (AppGrouping *) appGrouping
{
	return [DB appGroupingForID:[label intValue]];
}


+ (NSString *)stringForAccountType:(GenericAccountType)anAccountType
{
	switch (anAccountType) 
	{
		case AccountTypeITC:
			return @"iTunes Connect";
		case AccountTypeNotifications:
			return @"Notifications";
		case AccountTypeApplyzer:
			return @"Applyzer";
		default:
			return nil;
	}
}


- (void) setAccountType:(GenericAccountType)newAccountType
{
	NSString *accountTypeString = [GenericAccount stringForAccountType:newAccountType];
	
	if (accountTypeString)
	{
		self.service = accountTypeString;
	}
}

- (GenericAccountType) accountType
{
	if ([service isEqualToString:@"iTunes Connect"])
	{
		return AccountTypeITC;
	}
	else if ([service isEqualToString:@"Notifications"])
	{
		return AccountTypeNotifications;
	}
	else if ([service isEqualToString:@"Applyzer"])
	{
		return AccountTypeApplyzer;
	}
	else 
	{
		return AccountTypeUnknown;
	}
}


@end
