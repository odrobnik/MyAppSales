//
//  InAppPurchase.h
//  ASiST
//
//  Created by Oliver on 25.11.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "Product.h"

@class App;


@interface InAppPurchase : Product_v1 
{
	// additions
	App *parent;
}

- (id) initWithTitle:(NSString *)title vendor_identifier:(NSString *)vendor_identifier apple_identifier:(NSUInteger)apple_identifier company_name:(NSString *)company_name parent:(App *)parentApp database:(sqlite3 *)db;

@property (assign, nonatomic) App *parent;

@end
