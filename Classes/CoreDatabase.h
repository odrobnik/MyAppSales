//
//  CoreDatabase.h
//  ASiST
//
//  Created by Oliver on 12.05.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "ReportTypes.h"

@interface CoreDatabase : NSObject 
{
	// Core Data Stack
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (CoreDatabase *)sharedInstance;


@end
