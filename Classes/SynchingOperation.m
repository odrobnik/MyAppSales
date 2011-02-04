//
//  SynchingOperation.m
//  ASiST
//
//  Created by Oliver Drobnik on 02.02.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "SynchingOperation.h"


@implementation SynchingOperation



#pragma mark Informing the Delegate of Status Changes

- (void)sendStartToDelegate
{
	// main thread
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(sendStartToDelegate)
							   withObject:nil waitUntilDone:YES];
		return;
	}
	
	if ([delegate respondsToSelector:@selector(downloadStartedForOperation:)])
	{
		[delegate downloadStartedForOperation:self];
	}
}

- (void)sendFinishToDelegate
{
	// main thread
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread:@selector(sendStartToDelegate)
							   withObject:nil waitUntilDone:YES];
		return;
	}
	
	// main thread
	if ([delegate respondsToSelector:@selector(downloadFinishedForOperation:)])
	{
		[delegate downloadFinishedForOperation:self];
	}
}

#pragma mark Status Messaging
- (void) sendStatusNotification:(id)message
{
	// need to send notifications on main thread
	[[NSNotificationCenter defaultCenter] postNotificationName:@"StatusMessage" object:nil userInfo:(id)message];
}

- (void) setStatus:(NSString *)message
{
	[self performSelectorOnMainThread:@selector(sendStatusNotification:) withObject:(id)message waitUntilDone:NO];
}

- (void) setStatusError:(NSString *)message
{
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", @"Error", @"type", nil];
	[self performSelectorOnMainThread:@selector(sendStatusNotification:) withObject:(id)tmpDict waitUntilDone:NO];
	[self sendFinishToDelegate];
}

- (void) setStatusSuccess:(NSString *)message
{
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", @"Success", @"type", nil];
	[self performSelectorOnMainThread:@selector(sendStatusNotification:) withObject:(id)tmpDict waitUntilDone:NO];
	workInProgress = NO;
	[self sendFinishToDelegate];
}

@synthesize delegate;

@end
