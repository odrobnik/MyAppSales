//
//  NSString+AJAX.h
//  ajax
//
//  Created by Oliver on 13.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//


@interface NSString (AJAX)


- (NSDictionary *)parametersFromAjaxStringCharactersScanned:(NSUInteger *)charactersScanned;

- (NSArray *)parametersFromAjaxSubmitString;
- (NSArray *)parametersFromAjaxSubmitStringForFunction:(NSString *)functionName;

- (NSString *)ajaxViewState;

+ (NSString *)ajaxRequestBodyWithParameters:(NSArray *)parameters viewState:(NSString *)viewState;
+ (NSString *)ajaxRequestBodyWithParameters:(NSArray *)parameters extraFormString:(NSString *)extraFormString viewState:(NSString *)viewState;


@end
