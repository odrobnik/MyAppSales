//
//  CoreDatabase.m
//  ASiST
//
//  Created by Oliver on 12.05.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "CoreDatabase.h"
#import "SynchingManager.h"

#import "NSString+Helpers.h"

#import "Product.h"

#import "Report.h"
#import "Sale.h"
#import "ProductGroup.h"

#import "YahooFinance.h"


static CoreDatabase *_sharedInstance = nil;

@implementation CoreDatabase


+ (CoreDatabase *)sharedInstance
{
	if (!_sharedInstance)
	{
		_sharedInstance = [[CoreDatabase alloc] init];
	}
	
	return _sharedInstance;
}

- (id) init
{
	if (self = [super init])
	{
		NSLog(@"Connected to: %@", [[CoreDatabase databaseStoreUrl] path]);
		
		// TODO: also import country list for updates
		
		if (![self countryForCode:@"AT"])
		{
			// initial import of country list
			NSString *path = [NSString pathForFileInDocuments:@"Countries.plist"];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:path])
			{
				// no override countries file in documents
				path = [[NSBundle mainBundle] pathForResource:@"Countries" ofType:@"plist"];
			}
			
			[self performSelector:@selector(importCountriesFromFile:) withObject:path];
		}
		
		
		newReportsByType = [[NSMutableDictionary alloc] init];
		newAppsByProductGroup = [[NSMutableDictionary alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willResignActive:) 
													 name:UIApplicationWillResignActiveNotification
												   object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[flagDictionary release];
	[newReportsByType release];
	[newAppsByProductGroup release];
	[countries release];
	
	[super dealloc];
}

#pragma mark Products
// sum all types and groups
- (NSInteger)numberOfNewApps
{
	NSInteger ret = 0;
	for (NSNumber *number in [newAppsByProductGroup allValues])
	{
		ret += [number intValue];
	}
	
	return ret;
}

- (void)incrementNewAppsOfProductGroupID:(NSString *)groupID
{
	NSInteger value = [[newAppsByProductGroup objectForKey:groupID] intValue]+1;
	[newAppsByProductGroup setObject:[NSNumber numberWithInt:value] forKey:groupID];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewAppsNumberChanged" object:nil userInfo:nil];
}

- (void)decrementNewAppsOfProductGroupID:(NSString *)groupID
{
	NSInteger value = MAX([[newAppsByProductGroup objectForKey:groupID] intValue]-1, 0);
	[newAppsByProductGroup setObject:[NSNumber numberWithInt:value] forKey:groupID];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewAppsNumberChanged" object:nil userInfo:nil];
}

- (Product *)productForAppleIdentifier:(NSInteger)appleIdentifier application:(BOOL)application
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:1];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"appleIdentifier = %d AND isInAppPurchase = %d", appleIdentifier, !application];
	[request setPredicate:predicate];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// No error, we don't know this app id yet
	}
	
	[request release];	
	
	return [fetchResults lastObject];
}

- (Product *)productForVendorIdentifier:(NSString *)vendorIdentifier application:(BOOL)application
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:1];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"vendorIdentifier = %@ AND isInAppPurchase = %d", vendorIdentifier, !application];
	[request setPredicate:predicate];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// No error, we don't know this app id yet
	}
	
	[request release];	
	
	return [fetchResults lastObject];
}

- (NSArray *)allApps
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:0];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isInAppPurchase = 0"];
	[request setPredicate:predicate];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// no apps
	}
	
	[request release];	
	
	return fetchResults;
}

- (NSMutableDictionary *)iconDictionary
{
	if (!iconDictionary)
	{
		iconDictionary = [[NSMutableDictionary alloc] init];
	}
	
	return iconDictionary;
}

- (UIImage *)iconImageForProduct:(Product *)product
{
	// try in-memory cache
	id memoryImage = [[self iconDictionary] objectForKey:product.appleIdentifier];
	
	//if (memoryImage && memoryImage != [NSNull null])
	if ([memoryImage isKindOfClass:[UIImage class]])
	{
		return memoryImage;
	}
	
	// try file cache
	NSString *imageFileName = [NSString stringWithFormat:@"%@.png", product.appleIdentifier];
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *imagePath = [cachesPath stringByAppendingPathComponent:imageFileName];
	
	UIImage *diskImage = [UIImage imageWithContentsOfFile:imagePath];
	
	if (diskImage)
	{
		[iconDictionary setObject:diskImage forKey:product.appleIdentifier];
		
		return diskImage;
	}
	
	if (memoryImage == [NSNull null])
	{
		// not on disk, but already loading
		return nil;
	}	
	
	// add placeholder to prevent double loading
	[iconDictionary setObject:[NSNull null] forKey:product.appleIdentifier];
	
	// request download
	[[SynchingManager sharedInstance] downloadIconForAppWithIdentifier:[product.appleIdentifier intValue]];	
	
	return nil;
}

#pragma mark Country
- (NSArray *)allCountriesWithAppStore
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Country" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setPropertiesToFetch:[NSArray arrayWithObjects:@"name",@"appStoreID", nil]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"appStoreID != nil"];
	[request setPredicate:predicate];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// no apps
	}
	
	[request release];	
	
	return fetchResults;
}

- (Country *) countryForName:(NSString *)countryName
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Country" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:1];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", countryName];
	[request setPredicate:predicate];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// Handle the error.
		NSLog(@"Cannot resolve country name '%@', please report this to oliver@drobnik.com", countryName);
	}
	
	[request release];	
	
	return [fetchResults lastObject];
}


- (Country *) countryForCode:(NSString *)code
{
	if ([code length]==2)
	{
		// iso2 code
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Country" inManagedObjectContext:self.managedObjectContext];
		[request setEntity:entity];	
		[request setFetchLimit:1];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"iso2 = %@", code];
		[request setPredicate:predicate];
		
		NSError *error;
		NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
		if (fetchResults == nil) 
		{
			// Handle the error.
			NSLog(@"Cannot resolve country code '%@', please report this to oliver@drobnik.com", code);
		}
		
		[request release];	
		
		return [fetchResults lastObject];
	}
	else
	{
		// most likely this is a country name
		
		if ([code isEqualToString:@"USA"])
		{
			return [self countryForName:@"United States"];
		}
		else 
		{
			return [self countryForName:code];
		}
	}
}

- (ReportRegion) regionForCountryCode:(NSString *)countryCode
{
	ReportRegion region = ReportRegionUnknown;
	if ([countryCode isEqualToString:@"AR"]||
		[countryCode isEqualToString:@"BR"]||
		[countryCode isEqualToString:@"CL"]||
		[countryCode isEqualToString:@"CO"]||
		[countryCode isEqualToString:@"CR"]||
		[countryCode isEqualToString:@"DO"]||
		[countryCode isEqualToString:@"EC"]||
		[countryCode isEqualToString:@"GT"]||
		[countryCode isEqualToString:@"JM"]||
		[countryCode isEqualToString:@"MX"]||
		[countryCode isEqualToString:@"PE"]||
		[countryCode isEqualToString:@"SV"]||
		[countryCode isEqualToString:@"US"]||
		[countryCode isEqualToString:@"UY"]||
		[countryCode isEqualToString:@"VR"]	||
		[countryCode isEqualToString:@"VE"]	
		) region=ReportRegionUSA;
	else if ([countryCode isEqualToString:@"AT"]||
			 [countryCode isEqualToString:@"BE"]||
			 [countryCode isEqualToString:@"CH"]||
			 [countryCode isEqualToString:@"CZ"]||
			 [countryCode isEqualToString:@"DE"]||
			 [countryCode isEqualToString:@"DK"]||
			 [countryCode isEqualToString:@"EE"]||
			 [countryCode isEqualToString:@"ES"]||
			 [countryCode isEqualToString:@"FI"]||
			 [countryCode isEqualToString:@"FR"]||
			 [countryCode isEqualToString:@"GR"]||
			 [countryCode isEqualToString:@"HU"]||
			 [countryCode isEqualToString:@"IE"]||
			 [countryCode isEqualToString:@"IT"]||
			 [countryCode isEqualToString:@"LT"]||
			 [countryCode isEqualToString:@"LU"]||
			 [countryCode isEqualToString:@"LV"]||
			 [countryCode isEqualToString:@"MT"]||
			 [countryCode isEqualToString:@"NL"]||
			 [countryCode isEqualToString:@"NO"]||
			 [countryCode isEqualToString:@"PL"]||
			 [countryCode isEqualToString:@"PT"]||
			 [countryCode isEqualToString:@"RO"]||
			 [countryCode isEqualToString:@"SE"]||
			 [countryCode isEqualToString:@"SI"]||
			 [countryCode isEqualToString:@"SK"]) region=ReportRegionEurope;
	else if ([countryCode isEqualToString:@"CA"]) region=ReportRegionCanada;
	else if ([countryCode isEqualToString:@"AU"]||
			 [countryCode isEqualToString:@"NZ"]) region=ReportRegionAustralia;
	else if ([countryCode isEqualToString:@"JP"]) region=ReportRegionJapan;
	else if ([countryCode isEqualToString:@"GB"]) region=ReportRegionUK;
	else region=ReportRegionRestOfWorld;
	
	return region;
}

- (NSMutableDictionary *)flagDictionary
{
	if (!flagDictionary)
	{
		flagDictionary = [[NSMutableDictionary alloc] init];
	}
	
	return flagDictionary;
}

- (UIImage *)flagImageForCountry:(Country *)country
{
	// try in-memory cache
	id memoryImage = [[self flagDictionary] objectForKey:country.iso3];
	
	//if (memoryImage && memoryImage != [NSNull null])
	if ([memoryImage isKindOfClass:[UIImage class]])
	{
		return memoryImage;
	}
	
	// try file cache
	NSString *imageFileName = [NSString stringWithFormat:@"%@.png", country.iso3];
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *imagePath = [cachesPath stringByAppendingPathComponent:imageFileName];
	
	UIImage *diskImage = [UIImage imageWithContentsOfFile:imagePath];
	
	if (diskImage)
	{
		[flagDictionary setObject:diskImage forKey:country.iso3];
		
		return diskImage;
	}
	
	if (memoryImage == [NSNull null])
	{
		// not on disk, but already loading
		return nil;
	}	
	
	// add placeholder to prevent double loading
	[flagDictionary setObject:[NSNull null] forKey:country.iso3];
	
	// request download
	[[SynchingManager sharedInstance] downloadFlagForCountryWithISO3:country.iso3];
	
	return nil;
}


#pragma mark Report

/*
 - (Report *) reportForDate:(NSDate *)reportDate type:(ReportType)reportType region:(ReportRegion)reportRegion productGroup:(ProductGroup *)productGroup
 {
 NSFetchRequest *fetchRequest = [self.managedObjectModel
 fetchRequestFromTemplateWithName:@"reportByKey"
 substitutionVariables:[NSDictionary dictionaryWithObject:reportDate forKey:@"salaryAverage"]];
 
 
 NSFetchRequest *request = [[NSFetchRequest alloc] init];
 NSEntityDescription *entity = [NSEntityDescription entityForName:@"Report" inManagedObjectContext:self.managedObjectContext];
 [request setEntity:entity];	
 
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fromDate = %@ AND reportType = %d AND region = %d AND productGroup.objectID = %@", 
 reportDate, reportType, reportRegion];
 [request setPredicate:predicate];
 
 productGroup.reports
 
 NSError *error;
 NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
 if (fetchResults == nil) {
 // Handle the error.
 }
 
 [request release];	
 
 return [fetchResults lastObject];
 
 return nil;
 }
 
 #pragma mark Report Insertion
 
 #pragma mark Inserting
 
 - (void) insertReportIfNotDuplicate:(Report_v1 *)newReport
 {
 if (!newReport.fromDate || !newReport.untilDate || !newReport.downloadedDate)
 {
 NSLog(@"NULL date encountered, ignoring report");
 return;
 }
 
 Report_v1 *existingReport = [self reportForDate:newReport.untilDate type:newReport.reportType region:newReport.region appGrouping:newReport.appGrouping];
 
 // only add it if there is no previously existing report
 if (!existingReport)
 {
 // no duplicate, add it
 
 [newReport insertIntoDatabase:database]; 
 [reports setObject:newReport forKey:[NSNumber numberWithInt:newReport.primaryKey]];
 
 
 // also add it to the type index
 NSMutableArray *arrayForThisType = [self reportsOfType:newReport.reportType];
 
 [arrayForThisType addObject:newReport];
 
 newReports ++;
 
 //[self calcAvgRoyaltiesForApps];
 [self sendNewReportNotification:newReport];
 
 // local number of daily/weekly new Reports tracking
 NSNumber *typeKey = [NSNumber numberWithInt:newReport.reportType];
 
 [newReportsByType setObject:[NSNumber numberWithInt:1 + [[newReportsByType objectForKey:typeKey] intValue]] forKey:typeKey];
 }
 }
 */

- (Report *)reportBeforeReport:(Report *)report
{
	NSParameterAssert(report);

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Report" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:1];
	
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"fromDate" ascending:NO];
	[request setSortDescriptors:[NSArray arrayWithObject:sort]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fromDate < %@ AND region == %@ AND productGrouping = %@ AND reportType = %@", report.fromDate, report.region, report.productGrouping, report.reportType];
	[request setPredicate:predicate];
	
	NSLog(@"predicate: %@", predicate);
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// Handle the error.
	}
	
	[request release];	
	
	return [fetchResults lastObject];
}

- (Report *)reportAfterReport:(Report *)report
{
	NSParameterAssert(report);
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Report" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:1];
	
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"fromDate" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sort]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fromDate > %@ AND region == %@ AND productGrouping = %@ AND reportType = %@", report.fromDate, report.region, report.productGrouping, report.reportType];
	[request setPredicate:predicate];
	
	NSLog(@"predicate: %@", predicate);

	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// Handle the error.
	}
	
	[request release];	
	
	return [fetchResults lastObject];
}

- (BOOL)hasNewReportsOfType:(ReportType)type productGroupID:(NSString *)groupID
{
	NSString *typeKey = [NSString stringWithFormat:@"%@-%d",groupID, type];
	
	return (BOOL) [[newReportsByType objectForKey:typeKey] intValue];
}


// sum all types and groups
- (NSInteger)numberOfNewReports
{
	NSInteger ret = 0;
	for (NSNumber *number in [newReportsByType allValues])
	{
		ret += [number intValue];
	}
	
	return ret;
}


- (void)incrementNewReportsOfType:(ReportType)type productGroupID:(NSString *)groupID
{
	NSString *typeKey = [NSString stringWithFormat:@"%@-%d", groupID, type];
	
	NSInteger value = [[newReportsByType objectForKey:typeKey] intValue]+1;
	[newReportsByType setObject:[NSNumber numberWithInt:value] forKey:typeKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewReportsNumberChanged" object:nil userInfo:nil];
}

- (void)decrementNewReportsOfType:(ReportType)type productGroupID:(NSString *)groupID
{
	NSString *typeKey = [NSString stringWithFormat:@"%@-%d", groupID, type];
	
	NSInteger value = MAX([[newReportsByType objectForKey:typeKey] intValue]-1, 0);
	[newReportsByType setObject:[NSNumber numberWithInt:value] forKey:typeKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewReportsNumberChanged" object:nil userInfo:nil];
}

- (NSArray *)indexOfReportsToIgnoreForProductGroupWithID:(NSString *)groupID
{
	ProductGroup *productGroup = [self productGroupForKey:groupID];
	
	
	if (!productGroup)
	{
		return nil;
	}
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Report" 
											  inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:0];
	
	[request setPropertiesToFetch:[NSArray arrayWithObjects:@"reportType", @"fromDate", @"untilDate", @"region", nil]];
	[request setResultType:NSDictionaryResultType];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"productGrouping == %@", productGroup];
	[request setPredicate:predicate];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// Handle the error.
	}
	
	[request release];	
	
	NSLog(@"%@", fetchResults);
	
	return fetchResults;	
}


- (void)removeReport:(Report *)report
{
	if ([report.isNew boolValue])
	{
		[self decrementNewReportsOfType:[report.reportType intValue] productGroupID:report.productGrouping.identifier];
	}
	
	[self.managedObjectContext deleteObject:report];
	[self save];
}

- (void) insertReportFromDict:(NSDictionary *)dict
{
	// detected values
	ReportType reportType = [[dict objectForKey:@"Type"] intValue]; 
	ReportRegion reportRegion = [[dict objectForKey:@"Region"] intValue];
	NSDate *fallbackDate = [dict objectForKey:@"FallbackDate"];
	
	NSString *groupingKey = [dict objectForKey:@"ProductGroupingKey"];
	ProductGroup *productGroup = [self productGroupForKey:groupingKey];
	
	NSDate *fromDate = nil;
	NSDate *untilDate = nil;
	NSDate *downloadedDate = [NSDate date];
	
	NSString *reportText = [dict objectForKey:@"Text"];
	
	// Make a list of apps in this report
	NSMutableSet *tmpProductsInReport = [NSMutableSet set];
	NSMutableSet *tmpAppsInReport = [NSMutableSet set];
	
	//salesByApp = [[NSMutableDictionary alloc] init];
	
	NSArray *lines = [reportText componentsSeparatedByString:@"\n"];
	NSEnumerator *enu = [lines objectEnumerator];
	NSString *oneLine;
	
	// first line = headers
	oneLine = [enu nextObject];
	NSArray *column_names = [oneLine arrayOfColumnNames];
	
	
	NSMutableSet *tmpSales = [NSMutableSet set];
	Product *productWithHighestID = nil;
	
	// work off all lines
	while((oneLine = [enu nextObject])&&[oneLine length])
	{
		NSString *from_date = [oneLine getValueForNamedColumn:@"Begin Date" headerNames:column_names];
		
		/*
		 if (!from_date)
		 {
		 // ITC Format as of Sept 2010
		 from_date = [oneLine getValueForNamedColumn:@"Start Date" headerNames:column_names];
		 }
		 */
		
		NSString *until_date = [oneLine getValueForNamedColumn:@"End Date" headerNames:column_names];
		NSString *appIDString = [oneLine getValueForNamedColumn:@"Apple Identifier" headerNames:column_names];
		NSUInteger appID = [appIDString intValue];
		NSString *vendor_identifier = [oneLine getValueForNamedColumn:@"Vendor Identifier" headerNames:column_names];
		
		if (!vendor_identifier)
		{
			// ITC Format as of Sept 2010
			vendor_identifier = [oneLine getValueForNamedColumn:@"SKU" headerNames:column_names];
		}
		
		NSString *company_name = [oneLine getValueForNamedColumn:@"Artist / Show" headerNames:column_names];
		if (!company_name)
		{
			// ITC Format as of Sept 2010
			company_name = [oneLine getValueForNamedColumn:@"Developer" headerNames:column_names];
		}
		/*
		 if (!company_name)
		 {
		 // ITC Financial Format as of Sept 2010
		 company_name = [oneLine getValueForNamedColumn:@"Artist/Show/Developer/Author" headerNames:column_names];
		 }
		 */
		
		
		NSString *title	= [oneLine getValueForNamedColumn:@"Title / Episode / Season" headerNames:column_names];
		if (!title)
		{
			// ITC Format as of Sept 2010
			title = [oneLine getValueForNamedColumn:@"Title" headerNames:column_names];
		}
		
		
		NSUInteger type_id;
		NSString *typeString = [oneLine getValueForNamedColumn:@"Product Type Identifier" headerNames:column_names];
		NSString *parentIDString = [oneLine getValueForNamedColumn:@"Parent Identifier" headerNames:column_names];
		
		NSInteger units = [[oneLine getValueForNamedColumn:@"Units" headerNames:column_names] intValue];
		
		NSString *royaltyPriceString = [oneLine getValueForNamedColumn:@"Royalty Price" headerNames:column_names];
		if (!royaltyPriceString)
		{
			// ITC Format as of Sept 2010
			royaltyPriceString = [oneLine getValueForNamedColumn:@"Developer Proceeds" headerNames:column_names];
		}
		
		/*
		 if (!royaltyPriceString)
		 {
		 // ITC Financial Format as of Sept 2010
		 royaltyPriceString = [oneLine getValueForNamedColumn:@"Partner Share" headerNames:column_names];
		 }
		 */
		double royalty_price = [royaltyPriceString doubleValue];
		
		
		NSString *royalty_currency	= [oneLine getValueForNamedColumn:@"Royalty Currency" headerNames:column_names];
		if (!royalty_currency)
		{
			// ITC Format as of Sept 2010
			// note: weekly reports has "Of"
			royalty_currency = [oneLine getValueForNamedColumn:@"Currency of Proceeds" headerNames:column_names];
		}
		/*
		 if (!royalty_currency)
		 {
		 // ITC Financial Format as of Sept 2010
		 royalty_currency = [oneLine getValueForNamedColumn:@"Partner Share Currency" headerNames:column_names];
		 }			
		 */
		
		double customer_price = [[oneLine getValueForNamedColumn:@"Customer Price" headerNames:column_names] doubleValue];
		NSString *customer_currency	= [oneLine getValueForNamedColumn:@"Customer Currency" headerNames:column_names];
		NSString *country_code	= [oneLine getValueForNamedColumn:@"Country Code" headerNames:column_names];
		/*
		 if (!country_code)
		 {
		 // ITC Financial Format as of Sept 2010
		 country_code = [oneLine getValueForNamedColumn:@"Country Of Sale" headerNames:column_names];
		 }	
		 */
		
		// BOOL financial_report = NO;
		
		// Sept 2010: company name now omitted for IAP
		if ((!from_date)&&(!royalty_currency)&&(!royalty_price)&&(!country_code))
		{
			// probably monthly financial report
			from_date = [oneLine getValueForNamedColumn:@"Start Date" headerNames:column_names];
			
			units = [[oneLine getValueForNamedColumn:@"Quantity" headerNames:column_names] intValue];
			company_name = [oneLine getValueForNamedColumn:@"Artist/Show/Developer" headerNames:column_names];
			
			if (!company_name)
			{	
				// try new format
				company_name = [oneLine getValueForNamedColumn:@"Artist/Show/Developer/Author" headerNames:column_names];
			}
			
			title	= [oneLine getValueForNamedColumn:@"Title" headerNames:column_names];
			royalty_currency	= [oneLine getValueForNamedColumn:@"Partner Share Currency" headerNames:column_names];
			royalty_price = [[oneLine getValueForNamedColumn:@"Partner Share" headerNames:column_names] doubleValue];
			country_code	= [oneLine getValueForNamedColumn:@"Country Of Sale" headerNames:column_names];
			
			
			//financial_report = YES;
			reportType = ReportTypeFinancial;
		}
		
		
		// filter if PARTNERVERSION is active
#ifdef PARTNERVERSION
		NSSet *onlyThese = PARTNERVERSION_FILTER_APPS_SET;
		if (![onlyThese containsObject:appIDString]&&![onlyThese containsObject:parentIDString])
		{
			appID=0; // causes this line to be ignored
		}
#endif
		
		
		/*
		 NSString *salesOrReturn = [oneLine getValueForNamedColumn:@"Promo Code" headerNames:column_names];
		 
		 if ([salesOrReturn length])
		 {
		 NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
		 for (NSString *oneCol in column_names)
		 {
		 NSString *v = [oneLine getValueForNamedColumn:oneCol headerNames:column_names];		
		 if (v)
		 {
		 [tmpDict setObject:v forKey:oneCol];
		 }
		 }
		 NSLog(@"Promo!: %@", tmpDict);
		 }
		 */
		
		// if all columns have a value then we accept the line
		if (from_date&&until_date&&appID&&vendor_identifier&&company_name&&title&&type_id&&units&&royalty_currency&&customer_currency&&country_code)
		{
			Product *saleProduct;
			
			if ([typeString hasPrefix:@"1"] || [typeString hasPrefix:@"7"])
			{
				saleProduct = [self productForAppleIdentifier:appID application:YES];
				
				if (!saleProduct)
				{
					saleProduct = (Product *)[NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
					saleProduct.title = title;
					saleProduct.vendorIdentifier = vendor_identifier;
					saleProduct.appleIdentifier = [NSNumber numberWithInt:appID];
					saleProduct.companyName = company_name;
					saleProduct.isInAppPurchase = [NSNumber numberWithBool:NO];
					saleProduct.productGroup = productGroup;
					
					[self incrementNewAppsOfProductGroupID:groupingKey];
				}
				else 
				{
					// Product already exist, get it's grouping
					if (saleProduct.productGroup)
					{
						productGroup = saleProduct.productGroup;
					}
					
					// if the grouping key does not match, update group
					if (![productGroup.identifier isEqualToString:groupingKey])
					{
						productGroup.identifier = groupingKey;
					}
				}
				
				[tmpAppsInReport addObject:saleProduct];
				
				// remember product with the highest ID and company name
				if (!productWithHighestID || [saleProduct.appleIdentifier compare:productWithHighestID.appleIdentifier] == NSOrderedDescending)
				{
					productWithHighestID = saleProduct;
				}
			}
			else
			{
				// In App Purchase
				saleProduct =[self productForAppleIdentifier:appID application:NO];
				
				Product *parentApp = [self productForVendorIdentifier:parentIDString application:YES];
				
				if (!saleProduct)
				{
					saleProduct = (Product *)[NSEntityDescription insertNewObjectForEntityForName:@"Product" 
																		   inManagedObjectContext:self.managedObjectContext];
					saleProduct.title = title;
					saleProduct.vendorIdentifier = vendor_identifier;
					saleProduct.appleIdentifier = [NSNumber numberWithInt:appID];
					saleProduct.companyName = company_name;
					saleProduct.isInAppPurchase = [NSNumber numberWithBool:YES];
					
					saleProduct.productGroup = productGroup;
				}
				else
				{
					// now the parent is present
					if (!saleProduct.parent)
					{
						saleProduct.parent = parentApp;
					}
					
					// now the parent of this IAP is present
					if (!saleProduct.productGroup && productGroup)
					{
						saleProduct.productGroup = productGroup;
					}
				}
			}
			
			if (![tmpProductsInReport containsObject:saleProduct])
			{
				[tmpProductsInReport addObject:saleProduct];
			}
			
			// detect region for financial reports
			if ((reportType == ReportTypeFinancial)&&(!reportRegion))
			{
				reportRegion = [self regionForCountryCode:country_code];
			}
			
			// detect report type
			if (reportType == ReportTypeUnknown)
			{
				if ([from_date isEqualToString:until_date])
				{	
					// day report
					reportType = ReportTypeDay;
				}
				else
				{	// week report
					reportType = ReportTypeWeek;
				}
			}
			
			// set report dates if not set
			if (!fromDate&&!untilDate)
			{
				fromDate = [from_date dateFromString];
				untilDate = [until_date dateFromString];
			}
			
			// add sale
			
			Sale *newSale =  (Sale *)[NSEntityDescription insertNewObjectForEntityForName:@"Sale" inManagedObjectContext:self.managedObjectContext];
			
			newSale.country = [self countryForCode:country_code];
			newSale.product = saleProduct;
			newSale.unitsSold = [NSNumber numberWithInt:units];
			newSale.royaltyPrice = [NSNumber numberWithDouble:royalty_price];
			newSale.royaltyCurrency = royalty_currency;
			newSale.customerPrice = [NSNumber numberWithDouble:customer_price];
			newSale.customerCurrency = customer_currency;
			newSale.transactionType = typeString;
			
			if (!newSale.product)
			{
				NSLog(@"%@ %@", newSale, reportText);
			}
			
			[tmpSales addObject:newSale];
		}
	}
	
	// if none of the products on this report has a group then this is a new one
	if (!productGroup && [tmpSales count])
	{
		productGroup =  (ProductGroup *)[NSEntityDescription insertNewObjectForEntityForName:@"ProductGroup" 
																	  inManagedObjectContext:self.managedObjectContext];
		
		productGroup.title = productWithHighestID.companyName;
		productGroup.identifier = groupingKey;
	}
	
	// update all products with this group
	for (Product *oneProduct in tmpProductsInReport)
	{
		oneProduct.productGroup = productGroup;
	}
	
	// possibly empty report, so we need to use fallback date
	if (!fromDate&&fallbackDate)
	{
		fromDate = fallbackDate;
	}
	
	if (!untilDate&&fallbackDate)
	{
		untilDate = fallbackDate;
	}
	
	// create a new report and fill in the parsed sales
	Report *report = (Report *)[NSEntityDescription insertNewObjectForEntityForName:@"Report" 
															 inManagedObjectContext:self.managedObjectContext];	
	
	
	report.fromDate = fromDate;
	report.untilDate = untilDate;
	report.downloadedDate = downloadedDate;
	report.region = [NSNumber numberWithInt:reportRegion];
	report.reportType = [NSNumber numberWithInt:reportType];
	report.productGrouping = productGroup;
	report.isNew = [NSNumber numberWithBool:YES];
	
	[report addSales:tmpSales];
	
	[self incrementNewReportsOfType:reportType productGroupID:productGroup.identifier];
	
	[self save];
}

#pragma mark Summaries

// propery adds the values from one sale to the fields of summary
- (void)addSale:(Sale *)sale toSummary:(ReportSummary *)summary
{
	if ([sale.transactionType hasPrefix:@"1"] || 
		[sale.transactionType hasPrefix:@"IA"])
	{
		// sale or refund
		double royalties = [sale.royaltyPrice doubleValue] * [sale.unitsSold doubleValue];
		
		// check if we need currency conversion
		BOOL needsConversion = (![sale.royaltyCurrency isEqualToString:summary.royaltyCurrency]);
		
		// convert from sale currency to summary currency
		if (needsConversion)
		{
			YahooFinance *yahoo = [YahooFinance sharedInstance];
			royalties = [yahoo convertToCurrency:summary.royaltyCurrency
										  amount:royalties
									fromCurrency:sale.royaltyCurrency];
		}
		
		double prevRoyalites = [summary.sumRoyalties doubleValue];
		
		summary.sumRoyalties = [NSNumber numberWithDouble:royalties + prevRoyalites];
		
		if ([sale.unitsSold intValue] > 0)
		{
			// sale
			int units = [sale.unitsSold intValue];
			int prevUnits = [summary.sumSales intValue];
			
			summary.sumSales = [NSNumber numberWithInt:units + prevUnits];
		}
		else 
		{
			// refund
			int units = [sale.unitsSold intValue];
			int prevUnits = [summary.sumRefunds intValue];
			
			summary.sumRefunds = [NSNumber numberWithInt:abs(units) + prevUnits];
		}
	}
	else if ([sale.transactionType hasPrefix:@"7"])
	{
		// update
		int units = [sale.unitsSold intValue];
		int prevUnits = [summary.sumUpdates intValue];
		
		summary.sumUpdates = [NSNumber numberWithInt:units + prevUnits];
	}
}

- (void)removeAllSummaries
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ReportSummary" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:0];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// Handle the error.
	}
	
	[request release];	
	
	for (NSManagedObject *obj in fetchResults)
	{
		[self.managedObjectContext deleteObject:obj];
	}
	
	[self save];
}


- (void)buildSummaryForReport:(Report *)report
{
	//[self removeAllSummaries];
	
	NSMutableDictionary *summaryByProductAndCountry = [NSMutableDictionary dictionary];
	
	// sum total in internal currency Euro
	
	ReportSummary *reportTotal = (ReportSummary *)[NSEntityDescription insertNewObjectForEntityForName:@"ReportSummary" 
																				inManagedObjectContext:self.managedObjectContext];
	reportTotal.report = report;
	reportTotal.product = nil; // all products
	reportTotal.country = nil; // all countries
	reportTotal.royaltyCurrency = @"EUR";
	
	report.totalSummary = reportTotal;
	
	// walk through the sales
	for (Sale *oneSale in report.sales)
	{
		// summary per product and country
		NSString *productCountryKey = [NSString stringWithFormat:@"%@-%@", oneSale.product.appleIdentifier, oneSale.country.iso3];
		ReportSummary *productCountrySummary = [summaryByProductAndCountry objectForKey:productCountryKey];
		
		if (!productCountrySummary)
		{
			productCountrySummary = (ReportSummary *)[NSEntityDescription insertNewObjectForEntityForName:@"ReportSummary" 
																	 inManagedObjectContext:self.managedObjectContext];
			productCountrySummary.report = report;
			productCountrySummary.product = oneSale.product;
			productCountrySummary.country = oneSale.country;
			productCountrySummary.royaltyCurrency = oneSale.royaltyCurrency;
			
			[summaryByProductAndCountry setObject:productCountrySummary forKey:productCountryKey];
		}
		
		// summary per product
		NSString *productAllCountriesKey = [NSString stringWithFormat:@"%@-*", oneSale.product.appleIdentifier];
		ReportSummary *summaryPerProduct = [summaryByProductAndCountry objectForKey:productAllCountriesKey];
		
		
				
		if (!summaryPerProduct)
		{
			summaryPerProduct = (ReportSummary *)[NSEntityDescription insertNewObjectForEntityForName:@"ReportSummary" 
																			   inManagedObjectContext:self.managedObjectContext];
			summaryPerProduct.report = report;
			summaryPerProduct.product = oneSale.product;
			summaryPerProduct.country = nil;  // all countries
			summaryPerProduct.royaltyCurrency = @"EUR";  // internal currency
			
			[summaryByProductAndCountry setObject:summaryPerProduct forKey:productAllCountriesKey];
		}
		
		// here we have a summary for the country as well as for the product (IAP/app)
		
		// add to individual sum per country and product
		[self addSale:oneSale toSummary:productCountrySummary];

		// add to individual sum per product
		[self addSale:oneSale toSummary:summaryPerProduct];
		
		// link individual country summaries as children of summary for product
		productCountrySummary.parent = summaryPerProduct;
		
		// add it to the total summary
		[self addSale:oneSale toSummary:reportTotal];
		
		
		// also have a summary of all IAPs for an app
		
		if ([oneSale.product.isInAppPurchase boolValue])
		{
			// IAP
			NSString *parentKey = [NSString stringWithFormat:@"%@-*", oneSale.product.parent.appleIdentifier];
			ReportSummary *parentSummary = [summaryByProductAndCountry objectForKey:parentKey];
			
			ReportSummary *iapSummary = parentSummary.childrenSummary;
			
			if (!iapSummary)
			{
				iapSummary = (ReportSummary *)[NSEntityDescription insertNewObjectForEntityForName:@"ReportSummary" 
																			inManagedObjectContext:self.managedObjectContext];
				iapSummary.report = nil;
				iapSummary.product = nil;
				iapSummary.country = nil;  // all countries
				iapSummary.royaltyCurrency = @"EUR";  // internal currency
				
				// the app that this IAP belongs to
				iapSummary.parentSummary = parentSummary;
			}
			
			[self addSale:oneSale toSummary:iapSummary];
		}
		else 
		{
			// App
			if (!oneSale.product && oneSale.country)
			{
				NSLog(@"??? %@", oneSale);
			}
			
			[report addAppSummariesObject:summaryPerProduct];
		}
	}
	
	[self save];
}

- (ReportSummary *)summaryForReport:(Report *)report
{
	if (!report.totalSummary)
	{
		[self buildSummaryForReport:report];
	}
	
	return report.totalSummary;
}

#pragma mark Reviews
- (Review *)reviewForHash:(NSString *)hash
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:1];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"appUserVersionHash == %@", hash];
	[request setPredicate:predicate];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// Handle the error.
		NSLog(@"Cannot review with hash '%@'.", hash);
	}
	
	[request release];	
	
	return [fetchResults lastObject];	
}

- (void)scrapeReviewsForApp:(Product *)app
{
	for (Country *oneCountry in [self allCountriesWithAppStore])
	{
		[[SynchingManager sharedInstance] scrapeForProduct:app country:oneCountry delegate:self];
	}
}

- (void) scrapeReviews
{
	NSDate *today = [NSDate date];
	[[NSUserDefaults standardUserDefaults] setObject:today forKey:@"ReviewsLastDownloaded"];
	
	// get apps unsorted
	for (Product *oneApp in [self allApps])
	{
		[self scrapeReviewsForApp:oneApp];
	}
}

/*
 - (void) didFinishRetrievingReviews:(NSArray *)scrapedReviews
 {
 for (NSDictionary *oneDict in scrapedReviews)
 {
 NSString *appID = [[oneDict objectForKey:@"AppID"] description];
 Product *product = [self productForAppleIdentifier:appID application:YES];
 Country *country = [self countryForCode:[oneDict objectForKey:@"ISO2"]];
 
 NSString *userName = [oneDict objectForKey:@"UserName"];
 NSString *appVersion = [oneDict objectForKey:@"Version"];
 
 
 if (product && country && userName && appVersion)
 {
 NSString *hash = [Review hashFromVersion:appVersion user:userName appID:appID];
 
 Review *review = [self reviewForHash:hash];
 
 BOOL textChanged = NO;
 
 if (!review)
 {
 // create a new review item
 review = (Review *)[NSEntityDescription insertNewObjectForEntityForName:@"Review" 
 inManagedObjectContext:self.managedObjectContext];
 review.country = country;
 review.userName = userName;
 review.appVersion = appVersion;
 
 review.appUserVersionHash = [Review hashFromVersion:appVersion user:userName appID:product.appleIdentifier];
 
 [product addReviewsObject:review];
 
 textChanged = YES;
 }
 
 review.title = [oneDict objectForKey:@"ReviewTitle"];
 
 NSString *newText = [oneDict objectForKey:@"ReviewText"];
 if (![review.text isEqualToString:newText])
 {
 review.text = newText;
 textChanged = YES;
 }
 
 review.date = [oneDict objectForKey:@"ReviewDate"];
 review.ratingPercent = [oneDict objectForKey:@"Rating"];
 
 // temporarily mark as new
 review.isNew = [NSNumber numberWithBool:YES];
 
 if (textChanged)
 {
 [self translateReview:review];
 }
 }
 else 
 {
 NSLog(@"Incomplete Review object: %@", oneDict);
 }
 }
 
 [self save];
 }
 */

- (void)translateReview:(Review *)review
{
	[[SynchingManager sharedInstance] translateReview:review delegate:self];
}

- (void) finishedTranslatingTextTo:(NSString *)translatedText context:(NSString *)context
{
	// the review that this is for
	Review *review = [self reviewForHash:context];
	
	review.textTranslated = translatedText;
	
	[self save];
}

- (NSArray *)allReviews
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	
	[request release];	
	
	return fetchResults;
}

- (void)removeAllReviewTranslations
{
	for (Review *oneReview in [self allReviews])
	{
		oneReview.textTranslated = nil;
	}
	
	[self save];
}

- (void)redoAllReviewTranslations
{
	for (Review *oneReview in [self allReviews])
	{
		[self translateReview:oneReview];
		oneReview.textTranslated = nil;
	}
	
	[self save];
}

#pragma mark -
#pragma mark Core Data stack

+ (NSURL *)databaseStoreUrl
{
	NSString *databaseFile = @"MyAppSalesCoreData.sqlite";
	NSString *storePath = [[NSString applicationDocumentsDirectory] stringByAppendingPathComponent:databaseFile];
	
	return [NSURL fileURLWithPath:storePath];
}


/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [CoreDatabase databaseStoreUrl];	
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	// Allow inferred migration from the original version of the application.
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        // Handle the error.
    }    
	
    return persistentStoreCoordinator;
}

- (void)save
{
	NSError *error;
	if (![self.managedObjectContext save:&error])
	{
		NSLog(@"Error saving CoreData DB: %@", [error localizedDescription]);
	}	
}

#pragma mark Grouping
- (ProductGroup *)productGroupForKey:(NSString *)key
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ProductGroup" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:1];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", key];
	[request setPredicate:predicate];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// No error, we don't know this app id yet
	}
	
	[request release];	
	
	return [fetchResults lastObject];
}

- (NSArray *)allProductGroups
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ProductGroup" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:0];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// no apps
	}
	
	[request release];	
	
	return fetchResults;
}

#pragma mark Notifications
- (void)willResignActive:(NSNotification *)notification
{	
	// reset new apps / reports
	[newReportsByType removeAllObjects];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewReportsNumberChanged" object:nil userInfo:nil];
	
	[newAppsByProductGroup removeAllObjects];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewAppsNumberChanged" object:nil userInfo:nil];
}

#pragma mark Properties

@synthesize countries;

@end
