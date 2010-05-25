//
//  NSString+DTUtilities.m
//  ASiST
//
//  Created by Oliver on 12.05.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "NSString+DTUtilities.h"


@implementation NSString (DTUtilities)



+ (NSString *)applicationDocumentsDirectory;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}
@end
