//
//  Sale.h
//  ASiST
//
//  Created by Oliver on 12.05.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
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
@property (nonatomic, retain) NSNumber * transactionType;
@property (nonatomic, retain) NSString * customerCurrency;
@property (nonatomic, retain) NSNumber * royaltyPrice;
@property (nonatomic, retain) NSString * royaltyCurrency;
@property (nonatomic, retain) Report * report;
@property (nonatomic, retain) Product * product;
@property (nonatomic, retain) Country * country;

@end



