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

- (void) finishedTranslatingTextTo:(NSString *)translatedText;

@end


@class LKGoogleTranslator;

@interface TranslationScraperOperation : NSOperation 
{
	NSObject *scraperDelegate;
	NSObject *delegate;   // for the queue
	
	BOOL workInProgress;

	BOOL isExecuting;
	
	LKGoogleTranslator *translator;
	
	NSString *fromLanguage;
	NSString *toLanguage;
	NSString *textToTranslate;

}

@property (nonatomic, assign) NSObject *delegate;

- (id) initForText:(NSString *)textToTrans fromLanguage:(NSString *)fromLang toLanguage:(NSString *)toLang delegate:(NSObject <TranslationScraperDelegate> *) transDelegate;


@end
