//
//  NSDate+Helpers.h
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (Helpers)


- (long) dayNumber;
- (BOOL) sameDateAs:(NSDate *) other;
- (NSDate *) dateAtBeginningOfDay;

+ (NSDate *) dateFromRFC2822String:(NSString *)rfc2822String;
+ (NSDate *) dateFromMonth:(int)month Year:(int)year;

@end
