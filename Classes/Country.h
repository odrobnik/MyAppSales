//
//  Country.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 06.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ReportSummary;
@class Review;
@class Sale;

@interface Country :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * iso3;
@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSString * iconImage;
@property (nonatomic, retain) NSString * iso2;
@property (nonatomic, retain) NSNumber * appStoreID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* sales;
@property (nonatomic, retain) NSSet* summaries;
@property (nonatomic, retain) NSSet* reviews;

@end


@interface Country (CoreDataGeneratedAccessors)
- (void)addSalesObject:(Sale *)value;
- (void)removeSalesObject:(Sale *)value;
- (void)addSales:(NSSet *)value;
- (void)removeSales:(NSSet *)value;

- (void)addSummariesObject:(ReportSummary *)value;
- (void)removeSummariesObject:(ReportSummary *)value;
- (void)addSummaries:(NSSet *)value;
- (void)removeSummaries:(NSSet *)value;

- (void)addReviewsObject:(Review *)value;
- (void)removeReviewsObject:(Review *)value;
- (void)addReviews:(NSSet *)value;
- (void)removeReviews:(NSSet *)value;

@end

