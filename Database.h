//
//  Database.h
//  ASiST
//
//  Created by Oliver on 28.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface Database : NSObject 
{
	// Opaque reference to the SQLite database.
    sqlite3 *database;
}

@property (nonatomic, readonly)  sqlite3 *database;

+ (Database *) sharedInstance;


@end
