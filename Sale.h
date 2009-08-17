//
//  Sale.h
//  ASiST
//
//  Created by Oliver Drobnik on 24.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Country, App;

typedef enum { TransactionTypeSale = 1, TransactionTypeFreeUpdate = 7 } TransactionType;


@interface Sale : NSObject {
	App *app;
	Country *country;
	NSInteger unitsSold;
	double royaltyPrice;
	NSString *royaltyCurrency;
	double customerPrice;
	NSString *customerCurrency;
	TransactionType transactionType;
}

@property(nonatomic, retain) Country *country;
@property(nonatomic, retain) App *app;
@property(nonatomic, assign) double royaltyPrice;
@property(nonatomic, retain) NSString *royaltyCurrency;
@property(nonatomic, assign) double customerPrice;
@property(nonatomic, retain) NSString *customerCurrency;
@property(nonatomic, assign) NSInteger unitsSold;
@property(nonatomic, assign) TransactionType transactionType;

- (id) initWithCountryCode:(Country *)acountry app:(App *)aapp units:(NSInteger)aunits royaltyPrice:(double)aprice royaltyCurrency:(NSString *)acurrency customerPrice:(double)c_price customerCurrency:(NSString *)c_currency transactionType:(TransactionType)ttype;

@end
