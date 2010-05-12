//
//  CountrySummary.h
//  ASiST
//
//  Created by Oliver Drobnik on 04.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Country_v1;


@interface CountrySummary : NSObject {
	Country_v1 *country;
	NSInteger sumSales;
	NSInteger sumUpdates;
	NSInteger sumRefunds;
	
	NSString *royaltyCurrency;
	double sumRoyalites;
}

@property (nonatomic, retain) Country_v1 *country;
@property (nonatomic, assign) NSInteger sumSales;
@property (nonatomic, assign) NSInteger sumUpdates;
@property (nonatomic, assign) NSInteger sumRefunds;
@property (nonatomic, retain) NSString *royaltyCurrency;
@property (nonatomic, assign) double sumRoyalites;


- (id)initWithCountry:(Country_v1 *)country sumSales:(NSInteger)sales sumUpdates:(NSInteger)updates sumRefunds:(NSInteger)refunds; 
- (NSComparisonResult)compareBySales:(CountrySummary *)otherSummary;

+ (CountrySummary *) blankSummary;
- (CountrySummary *) summaryByAddingSummary:(CountrySummary *)otherSummary;
- (void) addSummary:(CountrySummary *)otherSummary;

@end
