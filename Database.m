//
//  Database.m
//  ASiST
//
//  Created by Oliver on 28.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "Database.h"


// private methods
@interface Database ()
- (void) connect;
- (void) createEditableCopyOfDatabaseIfNeeded;
- (void) updateSchemaIfNeeded;
@end

static Database *_sharedInstance;

@implementation Database

@synthesize database;

+ (Database *) sharedInstance
{
	if (!_sharedInstance)
	{
		_sharedInstance = [[Database alloc] init];
	}
	return _sharedInstance;
}

- (id) init
{
	if (self = [super init])
	{
		// connect with database
		[self createEditableCopyOfDatabaseIfNeeded];
		[self connect];
		[self updateSchemaIfNeeded];
	}
	return self;
}

#pragma mark Connection
// Creates a writable copy of the bundled default database in the application Documents directory.
- (void)createEditableCopyOfDatabaseIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"apps.db"];
	//NSLog(@"DB: %@", writableDBPath);
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"apps.db"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}

- (void) connect
{
	// The database is stored in the documents directory 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"apps.db"];
	
	NSLog(@"Connected to DB %@", path);
	
	if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) 
	{
		// all is well
	}
	else
	{
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(database);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
        // Additional error handling, as appropriate...
    }	
}

- (void) disconnect
{
	sqlite3_close(database);
}

#pragma mark Schema Updating

- (void)executeSchemaUpdate:(NSString *)scriptName
{
	// scripts are in the app bundle
	NSString *scriptPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:scriptName];
	
	NSString *script = [NSString stringWithContentsOfFile:scriptPath];
	char *errmsg;
	
	if (sqlite3_exec(database, [script UTF8String], NULL, NULL, &errmsg)!=SQLITE_OK)
	{
 		sqlite3_close(database);
        NSAssert1(0, @"Failed to execute update script with message '%s'.", errmsg);
	}
}


- (void)updateSchemaIfNeeded
{
	int schema_version = 0;
	
	char *sql = "SELECT schema_version FROM meta";
	sqlite3_stmt *statement;
	// Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.        
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) 
	{
		if (sqlite3_step(statement) == SQLITE_ROW) 
		{
			// The second parameter indicates the column index into the result set.
			schema_version = sqlite3_column_int(statement, 0);
		}
		
	}
	else
	{
		// no schema version, version = 1
		schema_version = 0;
	}
	sqlite3_finalize(statement);

	
	// execute all updates incrementially which are necessary 
	switch (schema_version) {
		case 0:
			[self executeSchemaUpdate:@"update_0_to_1.sql"];
		default:
			break;
	}
}

@end
