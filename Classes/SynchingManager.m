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
	ItunesConnectDownloaderOperation *wu = [[ItunesConnectDownloaderOperation alloc] initForAccount:itcAccount];
	[wu setQueuePriority:NSOperationQueuePriorityVeryHigh];
	
	wu.reportsToIgnore = [[Database sharedInstance] allReports];
	wu.delegate = self;
	[queue addOperation:wu];
	[self toggleNetworkIndicator:YES];
	
	[wu release];
}


#pragma mark Call-Backs

- (void) downloadStartedForOperation:(NSOperation *)operation
{
	ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	appDelegate.refreshButton.enabled = NO;
	
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
		[self toggleNetworkIndicator:YES];
	
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
}

- (void) downloadFinishedForOperation:(NSOperation *)operation
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
		[self toggleNetworkIndicator:NO];
		
		// update sums
		[[Database sharedInstance] getTotals];
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		appDelegate.refreshButton.enabled = YES;
		
		
	}
	else 
	{
		[self toggleNetworkIndicator:YES];
	}
}

@end
