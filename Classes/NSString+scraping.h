//
//  NSString+scraping.h
//  ASiST
//
//  Created by Oliver on 26.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (scraping)

- (NSDictionary *)dictionaryOfAttributesFromTag;
- (NSArray *)arrayOfInputs;
- (NSArray *)arrayOfInputsForForm:(NSString *)formName;

- (NSString *)tagHTMLforTag:(NSString *)tag WithName:(NSString *)name;
- (NSString *)tagHTMLforTag:(NSString *)tag WithID:(NSString *)identifier;
- (NSString *)nameForTag:(NSString *)tag WithID:(NSString *)identifier;

@end
