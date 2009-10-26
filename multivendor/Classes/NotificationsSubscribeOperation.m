//
//  NotificationsSubscribeOperation.m
//  ASiST
//
//  Created by Oliver on 25.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "NotificationsSubscribeOperation.h"
#import "Account.h"
#import "NSString+Helpers.h"
#import "XMLdocument.h"
#import "MyAppSales.h"

@implementation NotificationsSubscribeOperation

@synthesize delegate;

- (id) initForAccount:(Account *)notificationsAccount subscribe:(BOOL)doSubscribe;
{
	if (self = [super init])
	{
		account = [notificationsAccount retain];
		workInProgress = YES;
		subscribeMode = doSubscribe;
	}
	
	return self;
}

- (void) dealloc
{
	[account release];
	
	[super dealloc];
}


- (void) failWithMessage:(NSString *)message
{
	[self setStatusError:message];
	workInProgress = NO;
	[self performSelectorOnMainThread:@selector(sendFinishToDelegate) withObject:nil waitUntilDone:YES];
}



- (void) main
{
	if (!(account.account&&account.password&&![account.account isEqualToString:@""]&&![account.password isEqualToString:@""]))
	{
		return;
	}
	
	// main thread
	if (delegate && [delegate respondsToSelector:@selector(downloadStartedForOperation:)])
	{
		[delegate performSelectorOnMainThread:@selector(downloadStartedForOperation:) withObject:self waitUntilDone:NO];
	}
	
	
	// get credential directly from Notifications
	NSString *URL = @"https://www.appnotifications.com/user_session.xml";
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]
									cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
								timeoutInterval:30.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"user_session[email]=%@&user_session[password]=%@", 
						   [account.account stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
						   [account.password stringByUrlEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	
	//[self setStatus:@"Sending Login Information"];
	NSURLResponse* response; 
	NSError* error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	

	
	/*if ([response isKindOfClass:[NSHTTPURLResponse class]])
	 {
	 NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
	 NSLog(@"%@", [http allHeaderFields]);
	 }*/
	
	if (error)
	{
		[self setStatusError:[error localizedDescription]];
		return;
	}
	
	if (!data) 
	{
		//[self setStatusError:@"No data received from login"];
		return;
	}
	
	NSString *token;
	
	// for unsubscribing we use previously cached token, subscribing we always check
	if (!subscribeMode&&account.label)
	{
		token = account.label;
	}
	else
	{
		XMLdocument *xml = [XMLdocument documentWithData:data];
		
		XMLelement *resp = [xml.documentRoot getNamedChild:@"Response"];
		XMLelement *xmlToken = [resp getNamedChild:@"single-access-token"];
		
		if (xmlToken)
		{
			token = xmlToken.text;
		}
		else
		{
			[self setStatusError:@"Notifications Login Failed"];
			token = nil;
		}
	}

	

	if (token)
	{
		MyAppSales *service = [[[MyAppSales alloc] init] autorelease];
		
		if (subscribeMode)
		{
			if ([service subscribeNotificationsWithEmail:nil token:token])
			{
				[self setStatusSuccess:@"Notifications Enabled"];
			}
			else
			{
				[self setStatusSuccess:@"Unknown Error"];
			}
		}
		else
		{
			if ([service unsubscribeNotificationsWithEmail:nil token:token])
			{
				[self setStatusSuccess:@"Notifications Disabled"];
			}
			else
			{
				[self setStatusSuccess:@"Unknown Error"];
			}
		}

		account.label = token;
	}
	else
	{
		[self setStatusError:@"Notifications Login Failed"];
	}
}


- (BOOL) isConcurrent
{
	return NO;
}

- (BOOL) isFinished
{
	return !workInProgress;
}

#pragma mark Status

- (void) sendFinishToDelegate
{
	// main thread
	if (delegate && [delegate respondsToSelector:@selector(downloadFinishedForOperation:)])
	{
		[delegate performSelectorOnMainThread:@selector(downloadFinishedForOperation:) withObject:self waitUntilDone:NO];
	}
}

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
	workInProgress = NO;
	[self sendFinishToDelegate];
}

- (void) setStatusSuccess:(NSString *)message
{
	NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", @"Success", @"type", nil];
	[self performSelectorOnMainThread:@selector(sendStatusNotification:) withObject:(id)tmpDict waitUntilDone:NO];
	workInProgress = NO;
	[self sendFinishToDelegate];
}

@end

