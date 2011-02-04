//
//  SynchingManager.h
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ItunesConnectDownloaderOperation.h"

@class App, Country_v1, GenericAccount, Review_v1;
@class Product, Country, Review;
@protocol ReviewScraperDelegate, TranslationScraperDelegate;


@interface SynchingManager : NSObject <ItunesConnectDownloaderOperationDelegate>
{
	NSOperationQueue *queue;
	NSUInteger activeOperations;
}

+ (SynchingManager *) sharedInstance;

// Notifications
- (void) subscribeToNotificationsWithAccount:(GenericAccount *)notificationsAccount;
- (void) unsubscribeToNotificationsWithAccount:(GenericAccount *)notificationsAccount;

// cancelling
- (void) cancelAllOperationsOfClass:(Class)class;
- (void) cancelAllSynching;

// iTunes Review Scraper
//- (void) scrapeForApp:(App *)reviewApp country:(Country_v1 *)reviewCountry delegate:(id<ReviewScraperDelegate>)scraperDelegate;
- (void) scrapeForApp:(App *)app country:(Country_v1 *)country delegate:(id<ReviewScraperDelegate>)scraperDelegate;
- (void) scrapeForProduct:(Product *)product country:(Country *)country delegate:(id<ReviewScraperDelegate>)scraperDelegate;


// Translation Downloader
- (void) translateReview_v1:(Review_v1 *)review delegate:(id<TranslationScraperDelegate>)scraperDelegate;
- (void) translateReview:(Review *)review delegate:(id<TranslationScraperDelegate>)scraperDelegate;
- (void) cancelAllTranslations;

// iTunes Connect Downloader
- (void) downloadForAccount:(GenericAccount *)itcAccount reportsToIgnore:(NSArray *)reportsArray;

// Country Flags Downloader
- (void)downloadFlagForCountryWithISO3:(NSString *)iso3;

// App Icons Downloader
- (void)downloadIconForAppWithIdentifier:(NSInteger)appID;

- (void) updateIndicators;
- (NSArray *) queuedOperationsOfClass:(Class)opClass;

- (BOOL) hasActiveOperations;

@end
