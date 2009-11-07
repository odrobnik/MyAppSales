//
//  TranslationScraperOperation.m
//  ASiST
//
//  Created by Oliver on 19.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "TranslationScraperOperation.h"
#import "LKGoogleTranslator.h"

@interface TranslationScraperOperation ()
- (void) sendFinishToDelegate;
@end;


@implementation TranslationScraperOperation

@synthesize delegate;

- (id) initForText:(NSString *)textToTrans fromLanguage:(NSString *)fromLang toLanguage:(NSString *)toLang delegate:(NSObject <TranslationScraperDelegate> *) transDelegate
{
	if (self = [super init])
	{
		scraperDelegate = transDelegate;
		
		workInProgress = YES;
		
		translator = [[LKGoogleTranslator alloc] init];
		
		fromLanguage = [fromLang retain];
		toLanguage = [toLang retain];
		textToTranslate = [textToTrans retain];
	}
	
	return self;
}

- (void) dealloc
{
	[fromLanguage release];
	[toLanguage release];
	[textToTranslate release];
	[translator release];
	[super dealloc];
}

- (void)main
{
	// main thread
	if (delegate && [delegate respondsToSelector:@selector(downloadStartedForOperation:)])
	{
		[delegate performSelectorOnMainThread:@selector(downloadStartedForOperation:) withObject:self waitUntilDone:NO];
	}
	
	NSString *translatedText;
	
	if (fromLanguage && ![fromLanguage isEqualToString:toLanguage])
	{
		translatedText = [translator translateText:textToTranslate fromLanguage:fromLanguage toLanguage:toLanguage];
	}
	else
	{
		translatedText = textToTranslate;
	}
		
	if ([translatedText length]&&scraperDelegate && [scraperDelegate respondsToSelector:@selector(finishedTranslatingTextTo:)])
	{
		// tell the delegate that we have a translation, and do it on main thread to be safe
		[scraperDelegate performSelectorOnMainThread:@selector(finishedTranslatingTextTo:) withObject:translatedText waitUntilDone:YES];
	}

	workInProgress = NO;
		
	[self sendFinishToDelegate];	
}

- (BOOL) isFinished
{
	return !workInProgress;
}

- (BOOL) isConcurrent
{
	return NO;
}

- (void)cancel
{
	[super cancel];
	workInProgress = NO;
}

#pragma mark Status

- (void) sendFinishToDelegate
{
	// main thread
	if (delegate && [delegate respondsToSelector:@selector(downloadFinishedForOperation:)])
	{
		[delegate performSelectorOnMainThread:@selector(downloadFinishedForOperation:) withObject:self waitUntilDone:NO];
	}
}




@end
