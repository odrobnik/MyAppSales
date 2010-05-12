//
//  ReviewDownloaderOperation.h
//  ASiST
//
//  Created by Oliver on 13.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class App, Country_v1;

@protocol ReviewScraperDelegate <NSObject>

@optional

- (void) didFinishRetrievingReviews:(NSArray *)scrapedReviews;

@end


@interface ReviewDownloaderOperation : NSOperation 
{
	//NSUInteger appID;
	//NSUInteger storeID;
	App *app;
	Country_v1 *country;
	

	NSObject <ReviewScraperDelegate> *scraperDelegate;
	NSObject *delegate;
	
	BOOL workInProgress;
	
	NSMutableArray *scrapedReviews;
}

@property (nonatomic, retain) App *app;
@property (nonatomic, retain) Country_v1 *country;
@property (nonatomic, assign) NSObject *delegate;


- (id) initForApp:(App *)reviewApp country:(Country_v1 *)reviewCountry delegate:(NSObject <ReviewScraperDelegate> *) scrDelegate;


@end
