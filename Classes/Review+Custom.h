//
//  Review+Custom.h
//  ASiST
//
//  Created by Oliver on 29.10.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Review.h"

@interface Review (Custom)

- (NSString *)stringAsHTML;

+ (NSString *)hashFromVersion:(NSString *)version user:(NSString *)user appID:(id)appID;


@end
