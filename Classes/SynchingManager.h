//
//  SynchingManager.h
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>



@class App, Country, Account, Review;
@protocol ReviewScraperDelegate, TranslationScraperDelegate;


@interface SynchingManager : NSObject
{
	NSOperationQueue *queue;
	NSUInteger activeOperations;
}

+ (SynchingManager *) sharedInstance;


// iTunes Review Scraper
- (void) scrapeForApp:(App *)reviewApp country:(Country *)reviewCountry delegate:(id<ReviewScraperDelegate>)scraperDelegate;

// Translation Downloader
- (void) translateReview:(Review *)review delegate:(id<TranslationScraperDelegate>)scraperDelegate;
- (void) cancelAllTranslations;

// iTunes Connect Downloader
- (void) downloadForAccount:(Account *)itcAccount reportsToIgnore:(NSArray *)reportsArray;

- (void) updateIndicators;


@end
