//
//  SynchingOperation.h
//  ASiST
//
//  Created by Oliver Drobnik on 02.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@class SynchingOperation;

@protocol SynchingOperationDelegate <NSObject>

- (void)downloadStartedForOperation:(SynchingOperation *)operation;
- (void)downloadFinishedForOperation:(SynchingOperation *)operation;

@end



@interface SynchingOperation : NSOperation 
{
	id <SynchingOperationDelegate> delegate;
}

- (void)sendStartToDelegate;
- (void)sendFinishToDelegate;

// status utility
- (void)setStatus:(NSString *)message;
- (void)finishWithErrorMessage:(NSString *)message;
- (void)finishWithSuccessMessage:(NSString *)message;

@property (nonatomic, assign) id <SynchingOperationDelegate> delegate;

@end
