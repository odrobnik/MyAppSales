//
//  CoreDatabase+Import_v1.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 03.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Database.h"
#import "CoreDatabase.h"

@interface CoreDatabase (Import_v1)

- (BOOL)databaseStoreExists;

- (void)importDatabase:(Database *)database;


@end
