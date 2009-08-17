//
//  Sale.m
//  ASiST
//
//  Created by Oliver Drobnik on 24.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import "Sale.h"


@implementation Sale

@synthesize country, unitsSold, app, royaltyPrice, royaltyCurrency,customerPrice, customerCurrency, transactionType;


- (id) initWithCountryCode:(Country *)acountry app:(App *)aapp units:(NSInteger)aunits royaltyPrice:(double)aprice royaltyCurrency:(NSString *)acurrency customerPrice:(double)c_price customerCurrency:(NSString *)c_currency transactionType:(TransactionType)ttype;
{
	if (self = [super init]) 
	{
		self.country = acountry;
		NSAssert(country, @"Country must not be null");
		self.unitsSold = aunits;
		self.app = aapp;
		self.royaltyPrice = aprice;
		self.royaltyCurrency = acurrency;
		self.customerPrice = c_price;
		self.customerCurrency = c_currency;
		self.transactionType = ttype;
	}
	
	return self;
}

- (void) dealloc
{
	[customerCurrency release];
	[royaltyCurrency release];
	[app release];
	[country release];
	[super dealloc];
}


@end
