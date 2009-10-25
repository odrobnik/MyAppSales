//
//  XMLdocument.h
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

@class XMLdocument;

#import "XMLelement.h"
#import <Foundation/NSXMLParser.h>

@protocol XMLdocumentDelegate <NSObject>

@optional

- (void) xmlDocumentDidFinish:(XMLdocument *)xmlDocuments;
- (void) xmlDocument:(XMLdocument *)xmlDocument didFailWithError:(NSError *)error;

- (NSURLCredential *) userCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
@end



@interface XMLdocument : NSObject

#if !TARGET_OS_IPHONE
<NSXMLParserDelegate>  // this only when building for Mac
#endif

{
	XMLelement *documentRoot;
	
	id <XMLdocumentDelegate> delegate;

	// parsing 
	XMLelement *currentElement;
	
	// lists
	NSMutableDictionary *namespaces;
	
	// url loading
	NSMutableData *receivedData;
	NSURLConnection *theConnection;
	
	BOOL doneLoading;
}

@property (nonatomic, retain) XMLelement *documentRoot;
@property (nonatomic, assign) id <XMLdocumentDelegate> delegate;
@property (nonatomic, readonly) BOOL doneLoading;

+ (XMLdocument *) documentWithString:(NSString *)xmlString;
+ (XMLdocument *) documentWithData:(NSData *)data;
+ (XMLdocument *) documentWithContentsOfFile:(NSString *)path;
+ (XMLdocument *) documentWithContentsOfFile:(NSString *)path delegate:(id<XMLdocumentDelegate>)XMLdocumentDelegate;
+ (XMLdocument *) documentWithContentsOfURL:(NSURL *)url;
+ (XMLdocument *) documentWithContentsOfURL:(NSURL *)url delegate:(id<XMLdocumentDelegate>)XMLdocumentDelegate;

- (id) initWithString:(NSString *)xmlString;
- (id) initWithData:(NSData *)data;
- (id) initWithContentsOfFile:(NSString *)path;
- (id) initWithContentsOfFile:(NSString *)path delegate:(id<XMLdocumentDelegate>)XMLdocumentDelegate;
- (id) initWithContentsOfURL:(NSURL *)url;
- (id) initWithContentsOfURL:(NSURL *)url delegate:(id<XMLdocumentDelegate>)XMLdocumentDelegate;

- (void) cancelLoading;

- (id) performActionOnElements:(SEL)selector target:(id)aTarget;

@end
