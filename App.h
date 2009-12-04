//
//  App.h
//  ASiST
//
//  Created by Oliver Drobnik on 20.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "Product.h"
#import "ReviewDownloaderOperation.h"
#import "TranslationScraperOperation.h"



@interface App : Product <ReviewScraperDelegate> {
	NSMutableArray *reviews;
	NSUInteger countNewReviews;
	
	// for Downloading Icon image
	NSMutableData *receivedData;
	NSURLConnection *theConnection;
	
	UIImage *iconImage;
	UIImage *iconImageNano;
	
}

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (id) initWithTitle:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name database:(sqlite3 *)db;

- (void)insertIntoDatabase:(sqlite3 *)db;
- (void)deleteFromDatabase;
- (void)updateInDatabase;    // used if title changes

- (void) loadImageFromBirne;

@property (retain, nonatomic) UIImage *iconImage;
@property (retain, nonatomic) UIImage *iconImageNano;

@property (assign, readonly, nonatomic) NSMutableArray *reviews;

@property (nonatomic, readonly) NSUInteger countNewReviews;

- (void) getAllReviews;
- (void) removeReviewTranslations;
- (NSString *) reviewsAsHTML;

- (NSArray *)inAppPurchases;

@end
