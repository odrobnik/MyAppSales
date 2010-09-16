//
//  NSString+scraping.h
//  ASiST
//
//  Created by Oliver on 26.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (scraping)


// retrieve INPUT tags 
- (NSArray *)arrayOfInputs;
- (NSArray *)arrayOfInputsForForm:(NSString *)formName;
- (NSDictionary *)dictionaryForInputInForm:(NSString *)formName withID:(NSString *)identifier;

// get html for specifically identified tags
- (NSString *)tagHTMLforTag:(NSString *)tag WithName:(NSString *)name;
- (NSString *)tagHTMLforTag:(NSString *)tag WithID:(NSString *)identifier;
- (NSArray *)arrayOfHTMLForTags:(NSString *)tag matchingPredicate:(NSPredicate *)predicate;

// name / id conversion
- (NSString *)nameForTag:(NSString *)tag WithID:(NSString *)identifier;

// getting the attributes of a single tag
- (NSDictionary *)dictionaryOfAttributesFromTag;
- (NSDictionary *)dictionaryOfAttributesForTag:(NSString *)tag WithID:(NSString *)identifier;
- (NSDictionary *)dictionaryOfAttributesForTag:(NSString *)tag WithName:(NSString *)name;

// getting options from select
- (NSArray *) optionsFromSelect;

// html manipulation
- (NSString *)innerText;

// generic tag matching
- (NSArray *)arrayOfTags:(NSString *)tag;
- (NSArray *)arrayOfTags:(NSString *)tag matchingPredicate:(NSPredicate *)predicate;

@end

typedef enum
{
	FormPostTypeMultipart = 1
} FormPostType;

@interface NSString (FormPosting)

+ (NSString *)bodyForFormPostWithType:(FormPostType)type valueDictionaries:(NSArray *)valueDictionaries;

+ (NSString *)multipartBoundaryString;

@end

