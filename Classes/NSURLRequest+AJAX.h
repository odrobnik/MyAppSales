//
//  NSURLRequest+AJAX.h
//  ASiST
//
//  Created by Oliver Drobnik on 9/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSString+AJAX.h"

@interface NSURLRequest (AJAX)

+ (NSURLRequest *)ajaxRequestWithParameters:(NSArray *)parameters viewState:(NSString *)string baseURL:(NSURL *)baseURL;
+ (NSURLRequest *)ajaxRequestWithParameters:(NSArray *)parameters extraFormString:(NSString *)extraFormString viewState:(NSString *)viewState baseURL:(NSURL *)baseURL;

@end
