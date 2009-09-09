//
//  iTunesConnect.h
//  ASiST
//
//  Created by Oliver Drobnik on 19.12.08.
//  Copyright 2008 drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "Account.h"

//typedef enum { ReportTypeDay = 0, ReportTypeWeek = 1, ReportTypeFinancial = 2, ReportTypeFree = 3 } ReportType;
//typedef enum { ReportRegionUnknown = 0, ReportRegionUSA = 1, ReportRegionEurope = 2, ReportRegionCanada = 3, ReportRegionAustralia = 4, ReportRegionUK = 5, ReportRegionJapan = 6, ReportRegionRestOfWorld} ReportRegion;

@class Report, App, YahooFinance, Account;

@interface iTunesConnect : NSObject 
{
	// login
	//NSString *username;
	//NSString *password;
	Account *account;
	
	// for HTTP
	NSMutableData *receivedData;
	NSURLConnection *theConnection;

	// for the state machine
	NSString *loginPostURL;
	int loginStep;
	
	NSString *downloadPostURL;
	
	// array to hold available daily reports and index of currently loading report
	NSArray *dayOptions;
	int dayOptionsIdx;

	// array to hold available weekly reports and index of currently loading report
	NSArray *weekOptions;
	int weekOptionsIdx;
	
	// Date formatter for reading dates in reports from apple
	NSDateFormatter *dateFormatterToRead;
	
	BOOL syncing;
	
	NSDate *lastSuccessfulLoginTime;
}


- (id) initWithAccount:(Account *)itcAccount;

//- (id) initWithLogin:(NSString *)user password:(NSString *)pass;
 

- (BOOL) requestDailyReport;
- (BOOL) requestWeeklyReport;

// login
//@property (nonatomic, retain) NSString *username;
//@property (nonatomic, retain) NSString *password;

@property (nonatomic, retain) NSDate *lastSuccessfulLoginTime;
@property (nonatomic, retain) Account *account;


- (void) setStatus:(NSString *)message;
- (void) toggleNetworkIndicator:(BOOL)isON;

- (void) loginAndSync;
- (void) sync;

@end
