// MyAppSales.h 

#import <Foundation/Foundation.h>
#import "WebService.h"

#import "NSString+Helpers.h"
#import "NSDate+xml.h"

#import "NSDataAdditions.h"

// NOTE: defining all complex type as class so that the order does not matter



#pragma mark Complex Type Interface Definitions 

#pragma mark -
#pragma mark Main WebService Interface
@interface MyAppSales : WebService
{
}

- (BOOL) subscribeNotificationsWithEmail:(NSString *)email token:(NSString *)token;
- (BOOL) isSubscribedToNotificationsWithEmail:(NSString *)email token:(NSString *)token;
- (BOOL) unsubscribeNotificationsWithEmail:(NSString *)email token:(NSString *)token;
- (NSDate *) latestReportDateWithReportType:(NSInteger)reportType reportRegionID:(NSInteger)reportRegionID;
- (BOOL) seenReportWithReportType:(NSInteger)reportType reportDate:(NSDate *)reportDate reportRegionID:(NSInteger)reportRegionID;

@end