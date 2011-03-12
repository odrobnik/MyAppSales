//
//  ProductSummary.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 14.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Product;

@interface ProductSummary :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * fromDate;
@property (nonatomic, retain) NSDate * toDate;
@property (nonatomic, retain) NSNumber * sumRoyalties;
@property (nonatomic, retain) NSNumber *sumUnits;
@property (nonatomic, retain) Product * product;

@end



