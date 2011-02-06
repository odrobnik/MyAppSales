//
//  CoreDatabase+Import_v1.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 03.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "CoreDatabase+Import_v1.h"
#import "CoreDatabase.h"
#import "NSString+Helpers.h"

@implementation CoreDatabase (Import_v1)


- (void)importCountriesFromFile:(NSString *)file
{
	NSArray *countryList = [NSArray arrayWithContentsOfFile:file];
	
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Country" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setFetchLimit:0];
	
	NSError *error;
	NSArray *existingCountries = [managedObjectContext executeFetchRequest:request error:&error];
	
	for (NSDictionary *countryDict in countryList)
	{
		NSPredicate *countryPred = [NSPredicate predicateWithFormat:@"iso3 == %@", [countryDict objectForKey:@"iso3"]];
		
		Country *country = [[existingCountries filteredArrayUsingPredicate:countryPred] lastObject];
		
		if (!country)
		{
			country = (Country *)[NSEntityDescription insertNewObjectForEntityForName:@"Country" 
																	inManagedObjectContext:self.managedObjectContext];
		}

		[country setValuesForKeysWithDictionary:countryDict];
	}
	
	[self save];
}

- (void)exportCountriesToFile:(NSString *)file
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Country" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];	
	[request setPropertiesToFetch:[NSArray arrayWithObjects:@"name",@"appStoreID", @"iso3", @"iso2", @"language", nil]];
	
	[request setResultType:NSDictionaryResultType];
	
	NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"iso3" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:desc]];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults == nil) 
	{
		// no apps
	}
	
	[request release];	
	
	[fetchResults writeToFile:file atomically:YES];
}

#pragma mark Importing
+ (BOOL)databaseStoreExists
{
    NSString *storePath = [[CoreDatabase databaseStoreUrl] path];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:storePath])
	{
		return YES;
	}
	
	return NO;
}

- (void)importDatabase:(Database *)database
{
	
//	NSMutableDictionary *countryLookup = [NSMutableDictionary dictionary];
	NSMutableDictionary *productLookup = [NSMutableDictionary dictionary];
	NSMutableDictionary *reportLookup = [NSMutableDictionary dictionary];
	NSMutableDictionary *groupingLookup = [NSMutableDictionary dictionary];
	
	
//	// countries
//	for (NSString *oneCountryKey in [database.countries allKeys])
//	{
//		Country_v1 *oneCountry = [database.countries objectForKey:oneCountryKey];
//		
//		// create a country for each
//		Country *country = (Country *)[NSEntityDescription insertNewObjectForEntityForName:@"Country" 
//																	inManagedObjectContext:self.managedObjectContext];
//		
//		country.iso2 = oneCountry.iso2;
//		country.iso3 = oneCountry.iso3;
//		
//		if (oneCountry.appStoreID)
//		{
//			country.appStoreID = [NSNumber numberWithInt:oneCountry.appStoreID];
//		}
//		
//		country.language = oneCountry.language;
//		country.name = oneCountry.name;
//		
//		[countryLookup setObject:country forKey:country.iso2];
//	}
	
	// groupings
	NSArray *allGroupings = [database appGroupings];
	
	for (AppGrouping *oneGrouping in allGroupings)
	{
		if ([oneGrouping.apps count])
		{
			// create a product group for each
			ProductGroup *group = (ProductGroup *)[NSEntityDescription insertNewObjectForEntityForName:@"ProductGroup" 
																				inManagedObjectContext:self.managedObjectContext];
			
			group.title = oneGrouping.myDescription;
			group.identifier = [NSString stringWithFormat:@"%d", oneGrouping.primaryKey]; 
			
			if ([group.title isEqualToString:@"Default"] || 
				[group.title isEqualToString:@"No Description"])
			{
				group.title = nil;
			}
			
			[groupingLookup setObject:group forKey:[NSNumber numberWithInt:oneGrouping.primaryKey]];
			
			// insert all apps for this group to it
			for (App *oneApp in oneGrouping.apps)
			{
				// create a product for each
				Product *product = (Product *)[NSEntityDescription insertNewObjectForEntityForName:@"Product" 
																			inManagedObjectContext:self.managedObjectContext];
				
				product.title = oneApp.title;
				product.vendorIdentifier = oneApp.vendor_identifier;
				product.companyName = oneApp.company_name;
				product.appleIdentifier = [NSNumber numberWithInt:oneApp.apple_identifier];
				product.lastReviewRefresh = oneApp.lastReviewRefresh;
				product.isInAppPurchase = [NSNumber numberWithBool:NO];
				
				[productLookup setObject:product forKey:product.appleIdentifier];
				
				
				// if we have no product group name, take the company name of the first app
				if (!group.title)
				{
					group.title = product.companyName;
				}
				
				[group addProductsObject:product];

				// add the app's iaps
				for (InAppPurchase *iap in [database iapsForApp:oneApp])
				{
					Product *iapProduct = (Product *)[NSEntityDescription insertNewObjectForEntityForName:@"Product" 
																				   inManagedObjectContext:self.managedObjectContext];
					
					iapProduct.title = iap.title;
					iapProduct.vendorIdentifier = iap.vendor_identifier;
					iapProduct.companyName = iap.company_name;
					iapProduct.appleIdentifier = [NSNumber numberWithInt:iap.apple_identifier];
					iapProduct.parent = product;  // establishes link
					iapProduct.isInAppPurchase = [NSNumber numberWithBool:YES];
					
					if (!product)
					{
						NSLog(@"No product!");
					}
					
					[productLookup setObject:iapProduct forKey:iapProduct.appleIdentifier];
				}
				
				// add the app's reviews
				 for (Review_v1 *oneReview in oneApp.reviews)
				 {
					 // create a review for each
					 Review *review = (Review *)[NSEntityDescription insertNewObjectForEntityForName:@"Review" 
					 inManagedObjectContext:self.managedObjectContext];
					 review.title = oneReview.title;
					 review.text = oneReview.review;
					 review.date = oneReview.date;
					 review.ratingPercent = [NSNumber numberWithDouble:oneReview.stars];
					 review.userName = oneReview.name;
					 review.country = [self countryForCode:oneReview.country.iso2];
					 review.appVersion = oneReview.version;
					 
					 review.app = product;
					 review.appUserVersionHash = [Review hashFromVersion:review.appVersion user:review.userName appID:product.appleIdentifier];
				 }
			}
		}
	}
	
	// migrate reports separately
	NSArray *allReports = [database allReports];
	
	NSLog(@"%d reports", [allReports count]);
	
	for (Report_v1 *oneReport in allReports)
	{
		// create a report for each
		Report *report = (Report *)[NSEntityDescription insertNewObjectForEntityForName:@"Report" 
																 inManagedObjectContext:self.managedObjectContext];
		
		report.downloadedDate = oneReport.downloadedDate;
		report.fromDate = oneReport.fromDate;
		report.untilDate = oneReport.untilDate;
		
		ProductGroup *group = [groupingLookup objectForKey:[NSNumber numberWithInt:oneReport.appGrouping.primaryKey]];
		
		report.productGrouping = group;  // that's the link
		
		if (oneReport.region != ReportRegionUnknown)
		{
			report.region = [NSNumber numberWithInt:oneReport.region];
		}
		
		report.reportType = [NSNumber numberWithInt:oneReport.reportType];
		
		[reportLookup setObject:report forKey:[NSNumber numberWithInt:oneReport.primaryKey]];
	}
	
	// migrate sales separately
	sqlite3_stmt *statement = nil;
	
	const char *sql = "SELECT country_code, units, app_id, royalty_price, royalty_currency,type_id,customer_price, customer_currency, report_id FROM sale";
	if (sqlite3_prepare_v2(database.database, sql, -1, &statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database.database));
	}
	
	while (sqlite3_step(statement) == SQLITE_ROW) 
	{
		NSString *cntry_code = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
		NSInteger units = (int)sqlite3_column_int(statement, 1);
		NSInteger app_id = (int)sqlite3_column_int(statement, 2);
		double royalty_price = (double)sqlite3_column_double(statement, 3);
		NSString *royalty_currency = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)];
		NSInteger ttype = (int)sqlite3_column_int(statement, 5);
		double customer_price = (double)sqlite3_column_double(statement, 6);
		NSString *customer_currency = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 7)];
		int report_id = (int)sqlite3_column_int(statement, 8);
		
		
		// create a sale line for each
		Sale *sale = (Sale *)[NSEntityDescription insertNewObjectForEntityForName:@"Sale" 
														   inManagedObjectContext:self.managedObjectContext];
		
		sale.country = [self countryForCode:cntry_code];
		sale.unitsSold = [NSNumber numberWithInt:units];
		sale.product = [productLookup objectForKey:[NSNumber numberWithInt:app_id]];
		
		if (!sale.product)
		{
			NSLog(@"%@", productLookup);
			NSLog(@"??? %@");
			
		}
		sale.royaltyCurrency = royalty_currency;
		sale.royaltyPrice = [NSNumber numberWithDouble:royalty_price];
		sale.customerCurrency = customer_currency;
		sale.customerPrice = [NSNumber numberWithDouble:customer_price];
		sale.report = [reportLookup objectForKey:[NSNumber numberWithInt:report_id]];
		
		if (ttype<100)
		{
			sale.transactionType = [NSString stringWithFormat:@"%d", ttype];
		}
		else 
		{
			sale.transactionType = @"IA1";  // reconstructed
		}
		
	}
	
	// don't need it any more
	sqlite3_finalize(statement);
	
	[self save];
	
	// export country plist
	NSString *path = [NSString pathForFileInDocuments:@"countries.plist"];
	NSLog(@"Countries export to %@", path);
	[self exportCountriesToFile:path];
}


@end
