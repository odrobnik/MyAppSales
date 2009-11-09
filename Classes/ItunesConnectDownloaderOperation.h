//
//  ItunesConnectDownloaderOperation.h
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GenericAccount;

@interface ItunesConnectDownloaderOperation : NSOperation 
{
	GenericAccount *account;
	
	NSArray *reportsToIgnore;
	
	NSObject *delegate;
	
	BOOL workInProgress;
}

@property (nonatomic, retain) NSArray *reportsToIgnore; 
@property (nonatomic, assign) NSObject *delegate;
 

- (id) initForAccount:(GenericAccount *)itcAccount;

// status utility
- (void) sendFinishToDelegate;
- (void) setStatus:(NSString *)message;
- (void) setStatusError:(NSString *)message;
- (void) setStatusSuccess:(NSString *)message;

@end
