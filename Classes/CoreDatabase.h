//
//  CoreDatabase.h
//  ASiST
//
//  Created by Oliver on 12.05.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "ReportTypes.h"

#import "Product.h"
#import "ProductSummary.h"
#import "Report.h"
#import "Sale.h"
#import "ProductGroup.h"
#import "ReportSummary.h"
#import "Country.h"
#import "Review.h"
#import "Review+Custom.h"

#import "GenericAccount.h"
#import "ReviewDownloaderOperation.h"
#import "TranslationScraperOperation.h"

@interface CoreDatabase : NSObject <ReviewScraperDelegate, TranslationScraperDelegate>
{
	// Icon Caches
	NSMutableDictionary *flagDictionary;
	NSMutableDictionary *iconDictionary;
	
	
	// Core Data Stack
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	
	
	// caches
	NSArray *countries;
	NSMutableDictionary *newReportsByType;
	NSMutableDictionary *newAppsByProductGroup;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) NSArray *countries;


+ (CoreDatabase *)sharedInstance;

- (void) insertReportFromDict:(NSDictionary *)dict;

- (void)save;

- (UIImage *)iconImageForProduct:(Product *)product;
- (UIImage *)flagImageForCountry:(Country *)country;

- (NSArray *)allCountriesWithAppStore;
- (Country *)countryForCode:(NSString *)code;
- (Product *)productForAppleIdentifier:(NSInteger)appleIdentifier application:(BOOL)application;
- (Product *)productForVendorIdentifier:(NSString *)vendorIdentifier application:(BOOL)application;

- (ProductSummary *)summaryForProduct:(Product *)product;
- (void)buildSummaryForProduct:(Product *)product;
- (void)buildSummaryForAllApps;

- (void)scrapeReviewsForApp:(Product *)app;
- (void)scrapeReviews;
- (Review *)reviewForHash:(NSString *)hash;
- (void)translateReview:(Review *)review;
- (void)removeAllReviewTranslations;
- (void)redoAllReviewTranslations;

- (ProductGroup *)productGroupForKey:(NSString *)key;

- (Report *)reportBeforeReport:(Report *)report;
- (Report *)reportAfterReport:(Report *)report;
- (void)removeReport:(Report *)report;
- (void)buildSummaryForReport:(Report *)report;
- (ReportSummary *)summaryForReport:(Report *)report;

+ (NSURL *)databaseStoreUrl;

- (BOOL)hasNewReportsOfType:(ReportType)type productGroupID:(NSString *)groupID;
- (NSInteger)numberOfNewReports;
- (void)incrementNewReportsOfType:(ReportType)type productGroupID:(NSString *)groupID;
- (void)decrementNewReportsOfType:(ReportType)type productGroupID:(NSString *)groupID;
- (NSArray *)indexOfReportsToIgnoreForProductGroupWithID:(NSString *)groupID;

- (NSInteger)numberOfNewApps;
- (void)incrementNewAppsOfProductGroupID:(NSString *)groupID;
- (void)decrementNewAppsOfProductGroupID:(NSString *)groupID;


@end
