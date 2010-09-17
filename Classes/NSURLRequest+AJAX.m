//
//  NSURLRequest+AJAX.m
//  ASiST
//
//  Created by Oliver Drobnik on 9/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSURLRequest+AJAX.h"


@implementation NSURLRequest (AJAX)



+ (NSURLRequest *)ajaxRequestWithParameters:(NSArray *)parameters viewState:(NSString *)viewState baseURL:(NSURL *)baseURL
{
	// find the dictionary
	NSDictionary *ajaxParameterDict = nil;
	
	for (id obj in parameters)
	{
		if ([obj isKindOfClass:[NSDictionary class]])
		{
			ajaxParameterDict = obj;
			break;
		}
	}
	
	NSString *actionUrl = [ajaxParameterDict objectForKey:@"actionUrl"];
	
	NSURL *fullBaseURL = [NSURL URLWithString:actionUrl relativeToURL:baseURL];
	
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:fullBaseURL
									cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
								timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	NSString *bodyString = [NSString ajaxRequestBodyWithParameters:parameters viewState:viewState];
	NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	[request setHTTPBody:bodyData];

	return request;
}


+ (NSURLRequest *)ajaxRequestWithParameters:(NSArray *)parameters extraFormString:(NSString *)extraFormString viewState:(NSString *)viewState baseURL:(NSURL *)baseURL
{
	// find the dictionary
	NSDictionary *ajaxParameterDict = nil;
	
	for (id obj in parameters)
	{
		if ([obj isKindOfClass:[NSDictionary class]])
		{
			ajaxParameterDict = obj;
			break;
		}
	}
	
	NSString *actionUrl = [ajaxParameterDict objectForKey:@"actionUrl"];
	
	NSURL *fullBaseURL = [NSURL URLWithString:actionUrl relativeToURL:baseURL];
	
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:fullBaseURL
														 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													 timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	
	NSString *bodyString = [NSString ajaxRequestBodyWithParameters:parameters extraFormString:extraFormString viewState:viewState];
	
	NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	[request setHTTPBody:bodyData];
	
	return request;
}

@end
