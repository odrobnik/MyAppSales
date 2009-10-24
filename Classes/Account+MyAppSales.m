//
//  Account+MyAppSales.m
//  ASiST
//
//  Created by Oliver on 24.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "Account+MyAppSales.h"
#import "Database.h"
#import "AppGrouping.h"

@implementation Account (MyAppSales)


- (void) setAppGrouping:(AppGrouping *)newAppGrouping
{
	self.label = [NSString stringWithFormat:@"%d", newAppGrouping.primaryKey];
}

- (AppGrouping *) appGrouping
{
	return [DB appGroupingForID:[label intValue]];
}

@end
