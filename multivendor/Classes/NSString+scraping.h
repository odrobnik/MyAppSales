//
//  NSString+scraping.h
//  ASiST
//
//  Created by Oliver on 26.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (scraping)

- (NSArray *)arrayOfInputs;
- (NSArray *)arrayOfInputsForForm:(NSString *)formName;
@end
