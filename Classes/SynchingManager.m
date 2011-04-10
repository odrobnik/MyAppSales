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
#import "NotificationsSubscribeOperation.h"
#import "Database.h"
#import "ASiSTAppDelegate.h"
#import "Review_v1.h"
#import "Country_v1.h"
#import "GenericAccount+MyAppSales.h"

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
	if ((self = [super init]))
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

#pragma mark Push Notifications

- (void) subscribeToNotificationsWithAccount:(GenericAccount *)notificationsAccount
{
	NotificationsSubscribeOperation *wu = [[NotificationsSubscribeOperation alloc] initForAccount:notificationsAccount subscribe:YES];
	[wu setQueuePriority:NSOperationQueuePriorityVeryHigh];
	
	wu.delegate = self;
		
	[queue addOperation:wu];
	[self toggleNetworkIndicator:YES];
	
	[wu release];
}

- (void) unsubscribeToNotificationsWithAccount:(GenericAccount *)notificationsAccount
{
	NotificationsSubscribeOperation *wu = [[NotificationsSubscribeOperation alloc] initForAccount:notificationsAccount subscribe:NO];
	[wu setQueuePriority:NSOperationQueuePriorityVeryHigh];
	
	wu.delegate = self;
	
	[queue addOperation:wu];
	[self toggleNetworkIndicator:YES];
	
	[wu release];
}
#pragma mark iTunes Reviews


- (void) scrapeForApp:(App *)reviewApp country:(Country_v1 *)reviewCountry delegate:(id<ReviewScraperDelegate>)scraperDelegate
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


- (void) downloadForAccount:(GenericAccount *)itcAccount reportsToIgnore:(NSArray *)reportsArray
{
	NSArray *previousITC = [self queuedOperationsOfClass:[ItunesConnectDownloaderOperation class]];
	
	ItunesConnectDownloaderOperation *wu = [[ItunesConnectDownloaderOperation alloc] initForAccount:itcAccount];
	[wu setQueuePriority:NSOperationQueuePriorityVeryHigh];
	
	wu.reportsToIgnore = reportsArray;
	
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


- (void) cancelAllOperationsOfClass:(Class)class
{
	NSArray *allOps = [self queuedOperationsOfClass:class];
	
	for (id oneOp in allOps)
	{
		[oneOp cancel];
	}
	
	[self updateIndicators]; // update counter
}



#pragma mark Call-Backs

- (void) downloadStartedForOperation:(NSOperation *)operation
{
	[self updateIndicators];
}




// Translation Downloader
- (void) translateReview:(Review_v1 *)review delegate:(id<TranslationScraperDelegate>)scraperDelegate
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
	[self cancelAllOperationsOfClass:[TranslationScraperOperation class]];
}

- (void) cancelAllSynching
{
	[queue cancelAllOperations];
	[self updateIndicators]; // update counter
}

- (NSInteger) countOfActiveOperations
{
	int active_count = 0;
	for (NSOperation *operation in [queue operations])
	{
		if (![operation isFinished]&&![operation isCancelled])
		{
			active_count ++;
		}
	}
	
	return active_count;
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
	
	if (!active_count)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AllDownloadsFinished" object:nil];
		
		[self toggleNetworkIndicator:NO];
		[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	}
	else 
	{
		[self toggleNetworkIndicator:YES];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"SynchingStarted" object:nil];
		
		// disable idle time why synching active
		[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	}
}

- (void) downloadFinishedForOperation:(NSOperation *)operation
{
	[self updateIndicators];
}

#pragma mark Querying the Queue

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

- (BOOL) hasActiveOperations
{
	return ([self countOfActiveOperations]>0);
}

@end
