//
//  SynchingManager.m
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "SynchingManager.h"

#import "ReviewDownloaderOperation.h"
#import "ItunesConnectDownloaderOperation.h"
#import "TranslationScraperOperation.h"
#import "Database.h"
#import "ASiSTAppDelegate.h"
#import "Review.h"
#import "Country.h"
#import "Account+MyAppSales.h"

@implementation SynchingManager

static SynchingManager * _sharedInstance;


+ (SynchingManager *) sharedInstance
{
	if (!_sharedInstance)
	{
		_sharedInstance = [[SynchingManager alloc] init];
	}
	
	return _sharedInstance;
}

- (id) init
{
	if (self = [super init])
	{
		queue = [[NSOperationQueue alloc] init];
		queue.maxConcurrentOperationCount = 10;  // more does not seem to improve time
	}
	
	return self;
}

- (void) dealloc
{
	[queue release];
	[super dealloc];
}

- (void) toggleNetworkIndicator:(BOOL)isOn
{
	UIApplication *application = [UIApplication sharedApplication];
	
	if (application.networkActivityIndicatorVisible == isOn) return;
	
	application.networkActivityIndicatorVisible = isOn;
}


#pragma mark iTunes Reviews


- (void) scrapeForApp:(App *)reviewApp country:(Country *)reviewCountry delegate:(id<ReviewScraperDelegate>)scraperDelegate
{
	ReviewDownloaderOperation *wu = [[ReviewDownloaderOperation alloc] initForApp:reviewApp country:reviewCountry delegate:scraperDelegate];
	wu.delegate = self;
	[queue addOperation:wu];
	[self toggleNetworkIndicator:YES];

	[wu release];
}

#pragma mark itunes Connect 

- (BOOL) downloadingFromITC
{
	for (NSOperation *oneOperation in [queue operations])
	{
		if ([oneOperation isKindOfClass:[ItunesConnectDownloaderOperation class]])
		{
			return YES;
		}
	}
	
	return NO;
}


- (void) downloadForAccount:(Account *)itcAccount reportsToIgnore:(NSArray *)reportsArray;
{
	NSArray *previousITC = [self queuedOperationsOfClass:[ItunesConnectDownloaderOperation class]];
	
	ItunesConnectDownloaderOperation *wu = [[ItunesConnectDownloaderOperation alloc] initForAccount:itcAccount];
	[wu setQueuePriority:NSOperationQueuePriorityVeryHigh];
	
	wu.reportsToIgnore = [[Database sharedInstance] allReportsWithAppGrouping:[itcAccount appGrouping]];
	wu.delegate = self;
	
	// if there are previous downloads we wait until they are done by making a new download dependent on them
	
	for (ItunesConnectDownloaderOperation *oneOp in previousITC)
	{
		[wu addDependency:oneOp];
	}
	
	[queue addOperation:wu];
	[self toggleNetworkIndicator:YES];
	
	[wu release];
}


#pragma mark Call-Backs

- (void) downloadStartedForOperation:(NSOperation *)operation
{
	[self updateIndicators];
}

// Translation Downloader
- (void) translateReview:(Review *)review delegate:(id<TranslationScraperDelegate>)scraperDelegate
{
	NSString *translationLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReviewTranslation"];
	
	if (translationLanguage&&![translationLanguage isEqualToString:@" "])
	{
		TranslationScraperOperation *wu = [[TranslationScraperOperation alloc] initForText:review.review fromLanguage:review.country.language toLanguage:translationLanguage delegate:scraperDelegate];
							
		wu.delegate = self;
		[queue addOperation:wu];
		//[self updateIndicators]; // update counter

		//[self toggleNetworkIndicator:YES];
	
		[wu release];
	}
}

- (void) cancelAllTranslations
{
	NSArray *allOps = [queue operations];
	
	for (id oneOp in allOps)
	{
		if ([oneOp isKindOfClass:[TranslationScraperOperation class]])
		{
			[oneOp cancel];
		}
	}
	
	[self updateIndicators]; // update counter
}

- (void) cancelAllSynching
{
	[queue cancelAllOperations];
	[self updateIndicators]; // update counter
}

- (void) updateIndicators
{
	int active_count = 0;
	for (NSOperation *operation in [queue operations])
	{
		if (![operation isFinished]&&![operation isCancelled])
		{
			active_count ++;
		}
	}
	
	//NSLog(@"%d of %d", active_count, [[queue operations] count]);
	if (!active_count)
	{
		
		// update sums
		[[Database sharedInstance] getTotals];
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		//NSLog(@"synching done");
		appDelegate.refreshButton.enabled = YES;
		[self toggleNetworkIndicator:NO];
		[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
		
	}
	else 
	{
		//NSLog(@"still active : %d of %d", active_count, [[queue operations] count]);
		[self toggleNetworkIndicator:YES];

		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		appDelegate.refreshButton.enabled = NO;
		
		// disable idle time why synching active
		[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
		
		
	}
}

- (void) downloadFinishedForOperation:(NSOperation *)operation
{
	[self updateIndicators];
}

- (NSArray *) queuedOperationsOfClass:(Class)opClass
{
	NSArray *allOps = [queue operations];
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (id oneOp in allOps)
	{
		if ([oneOp isKindOfClass:opClass])
		{
			[tmpArray addObject:oneOp];
		}
	}
	
	if ([tmpArray count])
	{
		return [NSArray arrayWithArray:tmpArray];
	}
	else 
	{
		return nil;
	}

}

@end
