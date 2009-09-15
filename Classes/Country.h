//
//  Country.h
//  ASiST
//
//  Created by Oliver Drobnik on 29.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunesConnect.h"


@interface Country : NSObject {
	UIImage *iconImage;
	NSString *iso2;
	NSString *iso3;
	NSString *name;
	
	NSUInteger appStoreID;
	
	BOOL usedInReport;
	
	// Opaque reference to the underlying database.
    sqlite3 *database;
	
	// for Downloading Icon image
	NSMutableData *receivedData;
	NSURLConnection *theConnection;
}

@property (nonatomic, retain) UIImage *iconImage;
@property (nonatomic, retain) NSString *iso2;
@property (nonatomic, retain) NSString *iso3;
@property (nonatomic, retain) NSString *name;

@property (nonatomic, assign) NSUInteger appStoreID;

@property (nonatomic, assign) BOOL usedInReport;

- (id)initWithISO3:(NSString *)pk database:(sqlite3 *)db;

- (void) loadImageFromBirne;
- (ReportRegion) reportRegion;


@end
