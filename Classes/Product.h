//
//  Product.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 14.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ProductGroup;
@class ReportSummary;
@class ProductSummary;
@class Review;
@class Sale;

@interface Product :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * lastReviewRefresh;
@property (nonatomic, retain) NSString * vendorIdentifier;
@property (nonatomic, retain) NSNumber * averageRoyaltiesPerDay;
@property (nonatomic, retain) NSNumber * appleIdentifier;
@property (nonatomic, retain) NSNumber * isInAppPurchase;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * newReviewsCount;
@property (nonatomic, retain) NSNumber * isNew;
@property (nonatomic, retain) NSString * companyName;
@property (nonatomic, retain) NSNumber * totalRoyalties;
@property (nonatomic, retain) NSNumber * totalUnits;
@property (nonatomic, retain) NSSet* summaries;
@property (nonatomic, retain) ProductSummary * totalSummary;
@property (nonatomic, retain) Product * parent;
@property (nonatomic, retain) ProductGroup * productGroup;
@property (nonatomic, retain) NSSet* reviews;
@property (nonatomic, retain) NSSet* children;
@property (nonatomic, retain) NSSet* sales;

@end


@interface Product (CoreDataGeneratedAccessors)
- (void)addSummariesObject:(ReportSummary *)value;
- (void)removeSummariesObject:(ReportSummary *)value;
- (void)addSummaries:(NSSet *)value;
- (void)removeSummaries:(NSSet *)value;

- (void)addReviewsObject:(Review *)value;
- (void)removeReviewsObject:(Review *)value;
- (void)addReviews:(NSSet *)value;
- (void)removeReviews:(NSSet *)value;

- (void)addChildrenObject:(Product *)value;
- (void)removeChildrenObject:(Product *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;

- (void)addSalesObject:(Sale *)value;
- (void)removeSalesObject:(Sale *)value;
- (void)addSales:(NSSet *)value;
- (void)removeSales:(NSSet *)value;

@end

