//
//  NSScanner+HTML.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 4/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSScanner+HTML.h"


@implementation NSScanner (HTML)

- (BOOL)scanFunctionString:(NSString **)string
{
    NSUInteger location = self.scanLocation;
    
    if (![self scanString:@"function" intoString:NULL])
    {
        self.scanLocation = location;
        return NO;
    }
    
    // shortcut: just scan everything until next }
    
    NSString *function;
    if (![self scanUpToString:@"}" intoString:&function])
    {
        self.scanLocation = location;
        return NO;
    }
    
    [self scanString:@"}" intoString:NULL];
    
    if (*string)
    {
        *string = [NSString stringWithFormat:@"function%@}", function];
    }
    
    return YES;
}

@end
