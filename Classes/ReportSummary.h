//
//  ReportSummary.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 06.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Country;
@class Product;
@class Report;

@interface ReportSummary :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * sumSales;
@property (nonatomic, retain) NSNumber * sumRoyalties;
@property (nonatomic, retain) NSNumber * sumRefunds;
@property (nonatomic, retain) NSNumber * sumUpdates;
@property (nonatomic, retain) NSString * royaltyCurrency;
@property (nonatomic, retain) ReportSummary * childrenSummary;
@property (nonatomic, retain) Product * product;
@property (nonatomic, retain) ReportSummary * parent;
@property (nonatomic, retain) ReportSummary * parentSummary;
@property (nonatomic, retain) Report * report;
@property (nonatomic, retain) NSSet* children;
@property (nonatomic, retain) Report * appSummaryOnReport;
@property (nonatomic, retain) Country * country;
@property (nonatomic, retain) Report * totalOnReport;

@end


@interface ReportSummary (CoreDataGeneratedAccessors)
- (void)addChildrenObject:(ReportSummary *)value;
- (void)removeChildrenObject:(ReportSummary *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;

@end

