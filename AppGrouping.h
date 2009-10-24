//
//  AppGrouping.h
//  ASiST
//
//  Created by Oliver on 21.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"


@interface AppGrouping : NSObject {
	
	NSUInteger primaryKey;
	NSString * myDescription;
	NSMutableSet *apps;
	
	// Opaque reference to the underlying database.
    sqlite3 *database;
	
	BOOL assignmentsChanged;
}

- (id) initWithAppSet:(NSSet *)appSet;
- (BOOL)containsAppsOfSet:(NSSet *)appSet;
- (void)appendAppsOfSet:(NSSet *)appSet;

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (void)insertIntoDatabase:(sqlite3 *)db;
- (void)updateInDatabase;
- (void)deleteFromDatabase;

- (void)snatchReportsFromAppGrouping:(AppGrouping *)otherGrouping;

@property (nonatomic, readonly) NSUInteger primaryKey;
@property (nonatomic, retain) NSString *myDescription;
@property (nonatomic, retain) NSMutableSet *apps;
@end
