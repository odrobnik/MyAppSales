//
//  NSString+Helpers.h
//  ASiST
//
//  Created by Oliver on 15.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSString (Helpers)

// helper function
- (NSString *) getValueForNamedColumn:(NSString *)column_name  headerNames:(NSArray *)header_names;
- (NSDate *) dateFromString;
- (NSArray *) optionsFromSelect;



@end
