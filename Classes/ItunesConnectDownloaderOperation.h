//
//  ItunesConnectDownloaderOperation.h
//  ASiST
//
//  Created by Oliver on 14.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SynchingOperation.h"

@class GenericAccount, ItunesConnectDownloaderOperation;

@protocol ItunesConnectDownloaderOperationDelegate <NSObject, SynchingOperationDelegate>

- (void)itunesConnectDownloaderOperation:(ItunesConnectDownloaderOperation *)operation didDownloadReportDictionary:(NSDictionary *)dictionary;

@end


@interface ItunesConnectDownloaderOperation : SynchingOperation 
{
	GenericAccount *account;
	
	NSArray *reportsToIgnore;
	
	BOOL alternateLogin;
	
	NSString *productGroupingKey;
}

@property (nonatomic, retain) NSArray *reportsToIgnore; 
@property (nonatomic, assign) id <ItunesConnectDownloaderOperationDelegate> delegate;


- (id) initForAccount:(GenericAccount *)itcAccount;



@end
