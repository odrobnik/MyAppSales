//
//  AppGrouping.m
//  ASiST
//
//  Created by Oliver on 21.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "AppGrouping.h"
#import "App.h"

static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *init_apps_statement = nil;
static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *insert_apps_statement = nil;
static sqlite3_stmt *update_statement = nil;
static sqlite3_stmt *delete_statement = nil;

@implementation AppGrouping

@synthesize myDescription, apps, primaryKey;



- (id) initWithAppSet:(NSSet *)appSet
{
	if (self = [super init])
	{
		apps = [[NSMutableSet alloc] initWithSet:appSet];
	}
	
	return self;
}

- (void) dealloc
{
	[apps release];
	[myDescription release];
	[super dealloc];
}

- (BOOL)containsAppsOfSet:(NSSet *)appSet
{
	return [appSet intersectsSet:apps];
}

- (void)appendAppsOfSet:(NSSet *)appSet
{
	int previousCount = [apps count];
	[apps unionSet:appSet];
	
	if (previousCount < [apps count])
	{
		// something added
		assignmentsChanged = YES;
	}
}

#pragma mark Database
- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    if (self = [super init]) 
	{
        primaryKey = pk;
        database = db;

        if (init_statement == nil) 
		{
            const char *sql = "SELECT description FROM AppGrouping WHERE id=?";
            if (sqlite3_prepare_v2(database, sql, -1, &init_statement, NULL) != SQLITE_OK) 
			{
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }

        sqlite3_bind_int(init_statement, 1, primaryKey);
        if (sqlite3_step(init_statement) == SQLITE_ROW) 
		{
			self.myDescription = [NSString stringWithUTF8String:(char *)sqlite3_column_text(init_statement, 0)];
        } else {
        }
        // Reset the statement for future reuse.
        sqlite3_reset(init_statement);
		
		// load app assigments for this grouping
		apps = [[NSMutableSet alloc] init];

        if (init_apps_statement == nil) 
		{
			const char *sql = "SELECT app_id FROM AppAppGrouping WHERE appgrouping_id=?";
            if (sqlite3_prepare_v2(database, sql, -1, &init_apps_statement, NULL) != SQLITE_OK) 
			{
                NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
            }
        }

        sqlite3_bind_int(init_apps_statement, 1, primaryKey);
        while (sqlite3_step(init_apps_statement) == SQLITE_ROW) 
		{
			NSUInteger appID = sqlite3_column_int(init_apps_statement, 0);
			App *assignedApp = [DB appForID:appID];
			[apps addObject:assignedApp];
        }
        // Reset the statement for future reuse.
        sqlite3_reset(init_apps_statement);
    }
    return self;
}

- (void)insertAppGroupingsIntoDatabase
{
	if (insert_apps_statement == nil) {
		static char *sql = "INSERT INTO AppAppGrouping(appgrouping_id, app_id) VALUES(?, ?)";
		if (sqlite3_prepare_v2(database, sql, -1, &insert_apps_statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
	}
	
	for (App *oneApp in apps)
	{
		sqlite3_bind_int(insert_apps_statement, 1, primaryKey);
		sqlite3_bind_int(insert_apps_statement, 2, oneApp.apple_identifier);
		
		int success = sqlite3_step(insert_apps_statement);
		// Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
		sqlite3_reset(insert_apps_statement);
		if (success == SQLITE_ERROR) {
			NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
		}	
	}
}
	
- (void)deleteAppGroupingsFromDatabase
{
	sqlite3_stmt *tmp_statement = NULL;
	const char *sql = "DELETE FROM AppAppGrouping WHERE appgrouping_id=?";
	
	if (sqlite3_prepare_v2(database, sql, -1, &tmp_statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	else
	{
		// Bind the primary key variable.
		sqlite3_bind_int(tmp_statement, 1, primaryKey);
		// Execute the query.
		int success = sqlite3_step(tmp_statement);
		sqlite3_finalize(tmp_statement);
		// Handle errors.
		if (success != SQLITE_DONE) 
		{
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
		}
	}
}

- (void)insertIntoDatabase:(sqlite3 *)db {
    database = db;
	
    if (insert_statement == nil) {
        static char *sql = "INSERT INTO AppGrouping(description) VALUES(?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
	
	sqlite3_bind_text(insert_statement, 1, [@"No Description" UTF8String], -1, SQLITE_TRANSIENT);
	
    int success = sqlite3_step(insert_statement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insert_statement);
    if (success == SQLITE_ERROR) {
        NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
    } else {
        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
        // in the database. To access this functionality, the table should have a column declared of type 
        // "INTEGER PRIMARY KEY"
        
		primaryKey = sqlite3_last_insert_rowid(database);
		
		[self insertAppGroupingsIntoDatabase];
    }
}

- (void)updateInDatabase {
    // Compile the delete statement if needed.
    if (update_statement == nil) {
        const char *sql = "UPDATE AppGrouping set description = ? WHERE id=?";
        if (sqlite3_prepare_v2(database, sql, -1, &update_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_text(update_statement, 1, [myDescription UTF8String], -1, SQLITE_TRANSIENT);
    // Execute the query.
    int success = sqlite3_step(update_statement);
    // Reset the statement for future use.
    sqlite3_reset(update_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to update in database with message '%s'.", sqlite3_errmsg(database));
    }
	
	if (assignmentsChanged)
	{
		// remove existing assignments
		[self deleteAppGroupingsFromDatabase];
	
		// add all new assignments
		[self insertAppGroupingsIntoDatabase];
	}
}

- (void)deleteFromDatabase {
    // Compile the delete statement if needed.
    if (delete_statement == nil) {
        const char *sql = "DELETE FROM AppGrouping WHERE id=?";
        if (sqlite3_prepare_v2(database, sql, -1, &delete_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    // Bind the primary key variable.
    sqlite3_bind_int(delete_statement, 1, primaryKey);
    // Execute the query.
    int success = sqlite3_step(delete_statement);
    // Reset the statement for future use.
    sqlite3_reset(delete_statement);
    // Handle errors.
    if (success != SQLITE_DONE) {
        NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
    }
}

- (void)snatchReportsFromAppGrouping:(AppGrouping *)otherGrouping 
{
	sqlite3_stmt *statement;
         const char *sql = "UPDATE ReportAppGrouping SET AppGrouping_id = ? WHERE AppGrouping_id=?";
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK) 
		{
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    // Bind the primary key variable.
    sqlite3_bind_int(statement, 1, primaryKey);
    sqlite3_bind_int(statement, 2, otherGrouping.primaryKey);
	
    // Execute the query.
    int success = sqlite3_step(statement);
    // Reset the statement for future use.
    // Handle errors.
    if (success != SQLITE_DONE) 
	{
        NSAssert1(0, @"Error: failed to update from database with message '%s'.", sqlite3_errmsg(database));
    }
	sqlite3_finalize(statement);

	const char *sql2 = "UPDATE AppAppGrouping SET AppGrouping_id = ? WHERE AppGrouping_id=?";
	if (sqlite3_prepare_v2(database, sql2, -1, &statement, NULL) != SQLITE_OK) 
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
    // Bind the primary key variable.
    sqlite3_bind_int(statement, 1, primaryKey);
    sqlite3_bind_int(statement, 2, otherGrouping.primaryKey);
	
    // Execute the query.
    success = sqlite3_step(statement);
    // Reset the statement for future use.
    // Handle errors.
    if (success != SQLITE_DONE) 
	{
        NSAssert1(0, @"Error: failed to update from database with message '%s'.", sqlite3_errmsg(database));
    }
	sqlite3_finalize(statement);
}

@end
