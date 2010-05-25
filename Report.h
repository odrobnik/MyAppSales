//
//  Report.h
//  ASiST
//
//  Created by Oliver on 12.05.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ProductGroup;
@class ReportSummary;
@class Sale;

@interface Report :  NSManagedObject  
{
	
}

@property (nonatomic, retain) NSDate * fromDate;
@property (nonatomic, retain) NSNumber * sumUnitsSold;
@property (nonatomic, retain) NSNumber * sumUnitsFree;
@property (nonatomic, retain) NSNumber * sumUnitsUpdated;
@property (nonatomic, retain) NSDate * untilDate;
@property (nonatomic, retain) NSNumber * sumUnitsRefunded;
@property (nonatomic, retain) NSNumber * region;
@property (nonatomic, retain) NSDate * downloadedDate;
@property (nonatomic, retain) NSNumber * sumRoyaltiesEarned;
@property (nonatomic, retain) NSNumber * reportType;
@property (nonatomic, retain) ProductGroup * productGrouping;
@property (nonatomic, retain) NSSet* sales;
@property (nonatomic, retain) NSSet* summaries;

@end


@interface Report (CoreDataGeneratedAccessors)
- (void)addSalesObject:(Sale *)value;
- (void)removeSalesObject:(Sale *)value;
- (void)addSales:(NSSet *)value;
- (void)removeSales:(NSSet *)value;

- (void)addSummariesObject:(ReportSummary *)value;
- (void)removeSummariesObject:(ReportSummary *)value;
- (void)addSummaries:(NSSet *)value;
- (void)removeSummaries:(NSSet *)value;

@end

