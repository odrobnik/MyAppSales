//
//  CountrySummary.m
//  ASiST
//
//  Created by Oliver Drobnik on 04.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "CountrySummary.h"
#import "Country_v1.h"

@implementation CountrySummary

@synthesize country,sumSales,sumUpdates,sumRefunds, royaltyCurrency, sumRoyalites;

- (id)initWithCountry:(Country_v1 *)cntry sumSales:(NSInteger)sales sumUpdates:(NSInteger)updates sumRefunds:(NSInteger)refunds
{
	if ((self = [super init]))
	{
		self.country = cntry;
		self.sumSales = sales;
		self.sumUpdates = updates;
		self.sumRefunds = refunds;
	}
	return self;
}

+ (CountrySummary *) blankSummary
{
	return [[[CountrySummary alloc] initWithCountry:nil sumSales:0 sumUpdates:0 sumRefunds:0] autorelease];
}

- (void) dealloc
{
	[country release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@ - %d/%d/%d %.2f %@", country.iso3, sumSales, sumUpdates, sumRefunds, sumRoyalites, royaltyCurrency];
	
}

- (CountrySummary *) summaryByAddingSummary:(CountrySummary *)otherSummary
{
	CountrySummary *tmpSummary = [CountrySummary blankSummary];
	
	tmpSummary.sumSales = self.sumSales + otherSummary.sumSales;
	tmpSummary.sumUpdates = self.sumUpdates + otherSummary.sumUpdates;
	tmpSummary.sumRefunds = self.sumRefunds + otherSummary.sumRefunds;
	tmpSummary.sumRoyalites = self.sumRoyalites + otherSummary.sumRoyalites;
	
	return tmpSummary;
}

- (void) addSummary:(CountrySummary *)otherSummary
{
	self.sumSales += otherSummary.sumSales;
	self.sumUpdates += otherSummary.sumUpdates;
	self.sumRefunds += otherSummary.sumRefunds;
	self.sumRoyalites += otherSummary.sumRoyalites;
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
