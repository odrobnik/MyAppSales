//
//  TranslationScraperDelegate.h
//  ASiST
//
//  Created by Oliver on 19.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TranslationScraperDelegate <NSObject>

@optional

- (void) finishedTranslatingTextTo:(NSString *)translatedText context:(NSString *)context;

@end


@class LKGoogleTranslator;

@interface TranslationScraperOperation : NSOperation 
{
	id <TranslationScraperDelegate> scraperDelegate;
	id delegate;   // for the queue
	
	BOOL workInProgress;
	
	BOOL isExecuting;
	
	LKGoogleTranslator *translator;
	
	NSString *fromLanguage;
	NSString *toLanguage;
	NSString *textToTranslate;
	
	NSString *context;
}

@property (nonatomic, assign) id <TranslationScraperDelegate> scraperDelegate;
@property (nonatomic, assign) id delegate;

@property (nonatomic, retain) NSString *context;

- (id) initForText:(NSString *)textToTrans fromLanguage:(NSString *)fromLang toLanguage:(NSString *)toLang delegate:(NSObject <TranslationScraperDelegate> *) transDelegate;


@end
