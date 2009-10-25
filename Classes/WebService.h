//
//  WebService.h
//  SOAP
//
//  Created by Oliver on 16.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMLdocument;

typedef enum { SOAPVersionNone = 0, SOAPVersion1_0 = 1, SOAPVersion1_2 = 2 } SOAPVersion;

@interface WebService : NSObject {

}

- (NSURLRequest *) makeGETRequestWithLocation:(NSString *)url Parameters:(NSDictionary *)parameters;
- (NSURLRequest *) makePOSTRequestWithLocation:(NSString *)url Parameters:(NSDictionary *)parameters;
- (NSURLRequest *) makeSOAPRequestWithLocation:(NSString *)url Parameters:(NSArray *)parameters Operation:(NSString *)operation Namespace:(NSString *)namespace Action:(NSString *)action SOAPVersion:(SOAPVersion)soapVersion;

- (NSString *) returnValueFromSOAPResponse:(XMLdocument *)envelope;
- (id) returnComplexTypeFromSOAPResponse:(XMLdocument *)envelope asClass:(Class)retClass;
- (NSArray *) returnArrayFromSOAPResponse:(XMLdocument *)envelope withClass:(Class)retClass;
- (XMLdocument *) returnXMLDocumentFromSOAPResponse:(XMLdocument *)envelope;

- (BOOL) isBoolStringYES:(NSString *)string;

@end
