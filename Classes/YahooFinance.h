//
//  YahooFinance.h
//  ASiST
//
//  Created by Oliver Drobnik on 09.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface YahooFinance : NSObject {
//	NSMutableDictionary *curDict;
//	NSMutableDictionary *symbolDict;

	// for Downloading Currency data
	NSMutableData *receivedData;
	NSURLConnection *theConnection;
	
	NSString *mainCurrency;
	
	NSMutableDictionary *allCurrencies;
	NSMutableDictionary *nameIndex;
}

- (id) initWithAllCurrencies;
//- (id) initWithCurrencyList:(NSArray *)currencies;
- (void) parseYahooString:(NSString *)string;

- (void) save;

// conversion functions
- (double) convertToEuro:(double)amount fromCurrency:(NSString *)fromCurrency;
- (double) convertToCurrency:(NSString *)toCurrency amount:(double)amount fromCurrency:(NSString *)fromCurrency;
- (double) convertToMainCurrencyAmount:(double)amount fromCurrency:(NSString *)fromCurrency;


- (NSArray *)currencyList;
- (NSString *) formatAsCurrency:(NSString *)cur amount:(double)amount;

+ (YahooFinance *)sharedInstance;


@property (nonatomic, retain) NSString *mainCurrency;
@property (nonatomic, retain) NSMutableDictionary *allCurrencies;
@property (nonatomic, retain) NSMutableDictionary *nameIndex;
//@property (nonatomic, retain) NSDictionary *symbolDict;


@end
