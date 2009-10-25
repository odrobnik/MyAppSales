//
//  NSArray+XMLelement.h
//  SOAP
//
//  Created by Oliver on 15.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMLelement;

@interface NSArray (XMLelement)

- (XMLelement *)elementWhereAttribute:(NSString *)attribute HasValue:(NSString *)value;

@end
