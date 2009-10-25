// MyAppSales.m 

#import "MyAppSales.h"
#import "XMLdocument.h"

@implementation MyAppSales

- (BOOL) subscribeNotificationsWithEmail:(NSString *)email token:(NSString *)token
{
	NSString *location = @"http://www.drobnik.com/services/myappsales.asmx";
	NSMutableArray *paramArray = [NSMutableArray array];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"email", @"name",email, @"value", nil]];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"token", @"name",token, @"value", nil]];
	NSURLRequest *request = [self makeSOAPRequestWithLocation:location Parameters:paramArray Operation:@"SubscribeNotifications" Namespace:@"http://drobnik.net/" Action:@"http://drobnik.net/SubscribeNotifications" SOAPVersion:SOAPVersion1_0];
	NSURLResponse *response;
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	XMLdocument *xml = [XMLdocument documentWithData:data];
	NSString *result = [self returnValueFromSOAPResponse:xml];
	return (BOOL) [self isBoolStringYES:result];
}

- (BOOL) unsubscribeNotificationsWithEmail:(NSString *)email token:(NSString *)token
{
	NSString *location = @"http://www.drobnik.com/services/myappsales.asmx";
	NSMutableArray *paramArray = [NSMutableArray array];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"email", @"name",email, @"value", nil]];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"token", @"name",token, @"value", nil]];
	NSURLRequest *request = [self makeSOAPRequestWithLocation:location Parameters:paramArray Operation:@"UnsubscribeNotifications" Namespace:@"http://drobnik.net/" Action:@"http://drobnik.net/UnsubscribeNotifications" SOAPVersion:SOAPVersion1_0];
	NSURLResponse *response;
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	XMLdocument *xml = [XMLdocument documentWithData:data];
	NSString *result = [self returnValueFromSOAPResponse:xml];
	return (BOOL) [self isBoolStringYES:result];
}

- (NSDate *) latestReportDateWithReportType:(NSInteger)reportType reportRegionID:(NSInteger)reportRegionID
{
	NSString *location = @"http://www.drobnik.com/services/myappsales.asmx";
	NSMutableArray *paramArray = [NSMutableArray array];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ReportType", @"name",[NSNumber numberWithInt:reportType], @"value", nil]];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ReportRegionID", @"name",[NSNumber numberWithInt:reportRegionID], @"value", nil]];
	NSURLRequest *request = [self makeSOAPRequestWithLocation:location Parameters:paramArray Operation:@"LatestReportDate" Namespace:@"http://drobnik.net/" Action:@"http://drobnik.net/LatestReportDate" SOAPVersion:SOAPVersion1_0];
	NSURLResponse *response;
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	XMLdocument *xml = [XMLdocument documentWithData:data];
	NSString *result = [self returnValueFromSOAPResponse:xml];
	return (NSDate *) [result dateFromISO8601];
}

- (BOOL) seenReportWithReportType:(NSInteger)reportType reportDate:(NSDate *)reportDate reportRegionID:(NSInteger)reportRegionID
{
	NSString *location = @"http://www.drobnik.com/services/myappsales.asmx";
	NSMutableArray *paramArray = [NSMutableArray array];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ReportType", @"name",[NSNumber numberWithInt:reportType], @"value", nil]];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ReportDate", @"name",[reportDate ISO8601string], @"value", nil]];
	[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ReportRegionID", @"name",[NSNumber numberWithInt:reportRegionID], @"value", nil]];
	NSURLRequest *request = [self makeSOAPRequestWithLocation:location Parameters:paramArray Operation:@"SeenReport" Namespace:@"http://drobnik.net/" Action:@"http://drobnik.net/SeenReport" SOAPVersion:SOAPVersion1_0];
	NSURLResponse *response;
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	XMLdocument *xml = [XMLdocument documentWithData:data];
	NSString *result = [self returnValueFromSOAPResponse:xml];
	return (BOOL) [self isBoolStringYES:result];
}


@end