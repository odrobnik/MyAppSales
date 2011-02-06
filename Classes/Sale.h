//
//  Sale.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 06.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Country;
@class Product;
@class Report;

@interface Sale :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * unitsSold;
@property (nonatomic, retain) NSNumber * customerPrice;
@property (nonatomic, retain) NSString * transactionType;
@property (nonatomic, retain) NSString * customerCurrency;
@property (nonatomic, retain) NSNumber * royaltyPrice;
@property (nonatomic, retain) NSString * royaltyCurrency;
@property (nonatomic, retain) Report * report;
@property (nonatomic, retain) Product * product;
@property (nonatomic, retain) Country * country;

@end



