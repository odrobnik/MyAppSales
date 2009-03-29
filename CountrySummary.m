//
//  CountrySummary.m
//  ASiST
//
//  Created by Oliver Drobnik on 04.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CountrySummary.h"


@implementation CountrySummary

@synthesize country,sumSales,sumUpdates,sumRefunds, royaltyCurrency, sumRoyalites;

- (id)initWithCountry:(Country *)cntry sumSales:(NSInteger)sales sumUpdates:(NSInteger)updates sumRefunds:(NSInteger)refunds
{
	if (self = [super init]) 
	{
		self.country = cntry;
		self.sumSales = sales;
		self.sumUpdates = updates;
		self.sumRefunds = refunds;
	}
	return self;
}

- (void) dealloc
{
	[country release];
	[super dealloc];
}

- (NSComparisonResult)compareBySales:(CountrySummary *)otherSummary
{
	if (self.sumSales < otherSummary.sumSales)
	{
		return NSOrderedDescending;
	}
	
	if (self.sumSales > otherSummary.sumSales)
	{
		return NSOrderedAscending;
	}

	if (self.sumUpdates < otherSummary.sumUpdates)
	{
		return NSOrderedDescending;
	}
	
	if (self.sumUpdates > otherSummary.sumUpdates)
	{
		return NSOrderedAscending;
	}
	
	return NSOrderedSame;
}


@end
