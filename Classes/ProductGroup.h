//
//  ProductGroup.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 06.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Product;
@class Report;

@interface ProductGroup :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSSet* products;
@property (nonatomic, retain) NSSet* reports;

@end


@interface ProductGroup (CoreDataGeneratedAccessors)
- (void)addProductsObject:(Product *)value;
- (void)removeProductsObject:(Product *)value;
- (void)addProducts:(NSSet *)value;
- (void)removeProducts:(NSSet *)value;

- (void)addReportsObject:(Report *)value;
- (void)removeReportsObject:(Report *)value;
- (void)addReports:(NSSet *)value;
- (void)removeReports:(NSSet *)value;

@end

