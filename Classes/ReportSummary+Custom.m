//
//  ReportSummary+Custom.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 05.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "ReportSummary+Custom.h"
#import "Country.h"
#import "Product.h"

@implementation ReportSummary (Custom)

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ country=%@ product=%@ royalties=%.2f %@ units=%d refunds=%d updates=%d children=%d>", [self class],
			self.country.iso3, self.product.title,
			[self.sumRoyalties doubleValue], self.royaltyCurrency, [self.sumSales intValue], [self.sumRefunds intValue], 
			[self.sumUpdates intValue], [self.children count]];
}

@end
