//
//  ReviewDownloaderOperation.h
//  ASiST
//
//  Created by Oliver on 13.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ReviewScraperDelegate <NSObject>

@optional

- (void) didFinishRetrievingReviews:(NSArray *)scrapedReviews;

@end


@interface ReviewDownloaderOperation : NSOperation 
{
	NSObject <ReviewScraperDelegate> *scraperDelegate;
	NSObject *delegate;
	
	BOOL workInProgress;
	
	NSMutableArray *scrapedReviews;
	
	NSInteger _appID;
	NSInteger _storeID;
	NSString *iso2;
}

@property (nonatomic, assign) NSObject *delegate;
@property (nonatomic, assign) NSInteger appID;
@property (nonatomic, assign) NSInteger storeID;
@property (nonatomic, retain) NSString *iso2;



- (id) initForAppID:(NSInteger)appID storeID:(NSInteger)storeID delegate:(NSObject <ReviewScraperDelegate> *) scrDelegate;


@end
