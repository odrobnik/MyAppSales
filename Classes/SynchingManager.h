//
//  SynchingManager.h
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>



@class App, Country, Account;
@protocol ReviewScraperDelegate;


@interface SynchingManager : NSObject
{
	NSOperationQueue *queue;
}

+ (SynchingManager *) sharedInstance;


// iTunes Review Scraper
- (void) scrapeForApp:(App *)reviewApp country:(Country *)reviewCountry delegate:(id<ReviewScraperDelegate>)scraperDelegate;


// iTunes Connect Downloader
- (void) downloadForAccount:(Account *)itcAccount reportsToIgnore:(NSArray *)reportsArray;
@end
