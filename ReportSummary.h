//
//  ReportSummary.h
//  ASiST
//
//  Created by Oliver on 12.05.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Country;
@class Product;
@class Report;

@interface ReportSummary :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * sumRefunds;
@property (nonatomic, retain) NSNumber * sumRoyalites;
@property (nonatomic, retain) NSNumber * sumSales;
@property (nonatomic, retain) NSNumber * sumUpdates;
@property (nonatomic, retain) NSString * royaltyCurrency;
@property (nonatomic, retain) Report * report;
@property (nonatomic, retain) Product * product;
@property (nonatomic, retain) Country * country;

@end



