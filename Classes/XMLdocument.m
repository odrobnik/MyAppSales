//
//  XMLdocument.m
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "XMLdocument.h"
#import "XMLelement.h"
	

@implementation XMLdocument

@synthesize documentRoot, delegate, doneLoading;


+ (BOOL)accessInstanceVariablesDirectly
{
	return YES;
}

#pragma mark Factory Methods
+ (XMLdocument *) documentWithString:(NSString *)xmlString
{
	return [[[XMLdocument alloc] initWithString:xmlString] autorelease];
}

+ (XMLdocument *) documentWithData:(NSData *)data
{
	return [[[XMLdocument alloc] initWithData:data] autorelease];
}

+ (XMLdocument *) documentWithContentsOfFile:(NSString *)path
{
	return [[[XMLdocument alloc] initWithContentsOfFile:path] autorelease];
}

+ (XMLdocument *) documentWithContentsOfFile:(NSString *)path delegate:(id<XMLdocumentDelegate>)XMLdocumentDelegate
{
	return [[[XMLdocument alloc] initWithContentsOfFile:path delegate:XMLdocumentDelegate] autorelease];
}

+ (XMLdocument *) documentWithContentsOfURL:(NSURL *)url
{
	return [[[XMLdocument alloc] initWithContentsOfURL:url] autorelease];
}

+ (XMLdocument *) documentWithContentsOfURL:(NSURL *)url delegate:(id<XMLdocumentDelegate>)XMLdocumentDelegate
{
	return [[[XMLdocument alloc] initWithContentsOfURL:url delegate:XMLdocumentDelegate] autorelease];
}



#pragma mark Initializer
// designated initializer	
- (id) init
{
	if ((self = [super init]))
	{
	}
	
	return self;
}

- (id) initWithString:(NSString *)xmlString
{
	if (self = [self init])
	{
		// make data from string
		
		NSData *data = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
		
		// create parser
		NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:data] autorelease];	
		[parser setShouldProcessNamespaces: YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:self];
		
		if ([parser parse])
		{
			if (delegate && [delegate respondsToSelector:@selector(xmlDocumentDidFinish:)])
			{
				[delegate xmlDocumentDidFinish:self];
			}
		}
	}
	
	return self;
}

- (id) initWithData:(NSData *)data
{
	if (self = [self init])
	{
		// create parser
		NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:data] autorelease];	
		[parser setShouldProcessNamespaces: YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:self];
		
		if ([parser parse])
		{
			if (delegate && [delegate respondsToSelector:@selector(xmlDocumentDidFinish:)])
			{
				[delegate xmlDocumentDidFinish:self];
			}
		}
	}
	
	return self;
}

- (id) initWithContentsOfFile:(NSString *)path
{
	if (self = [self init])
	{
		
		// make a file path out of the parameter
		NSURL *fileURL = [NSURL fileURLWithPath:path]; 
		
		// create parser
		NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:fileURL] autorelease];	
		[parser setShouldProcessNamespaces: YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:self];
		
		if ([parser parse])
		{
			if (delegate && [delegate respondsToSelector:@selector(xmlDocumentDidFinish:)])
			{
				[delegate xmlDocumentDidFinish:self];
			}
		}
	}
	
	return self;
}

- (id) initWithContentsOfURL:(NSURL *)url
{
	if (self = [self init])
	{
		// create parser
		NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:url] autorelease];	
		[parser setShouldProcessNamespaces: YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:self];
		
		if ([parser parse])
		{
			if (delegate && [delegate respondsToSelector:@selector(xmlDocumentDidFinish:)])
			{
				[delegate xmlDocumentDidFinish:self];
			}
		}
	}
	
	return self;
}

- (id) initWithContentsOfFile:(NSString *)path delegate:(id<XMLdocumentDelegate>)XMLdocumentDelegate
{
	if (self = [self init])
	{
		self.delegate = XMLdocumentDelegate;
		
		// make a file path out of the parameter
		NSURL *fileURL = [NSURL fileURLWithPath:path]; 
		
		// create parser
		NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:fileURL] autorelease];	
		[parser setShouldProcessNamespaces: YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:NO];
		[parser setDelegate:self];
		
		if ([parser parse])
		{
			if (delegate && [delegate respondsToSelector:@selector(xmlDocumentDidFinish:)])
			{
				[delegate  xmlDocumentDidFinish:self];
			}
		}
	}
	
	return self;
}

- (id) initWithContentsOfURL:(NSURL *)url delegate:(id<XMLdocumentDelegate>)XMLdocumentDelegate
{
	if (self = [self init])
	{
		self.delegate = XMLdocumentDelegate;
		
		NSURLRequest *request=[NSURLRequest requestWithURL:url
								 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
							 timeoutInterval:60.0];
		
		theConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
		
		if (theConnection) 
		{
			receivedData=[[NSMutableData data] retain];
		}
	}
	
	return self;
}


- (void) dealloc
{
	[namespaces release];
	[theConnection release];
	[documentRoot release];
	
	[receivedData release];
	
	[super dealloc];
}

#pragma mark Parser Protocol

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{	
	XMLelement *newElement = [[XMLelement alloc] initWithName:elementName];
	newElement.attributes = [NSMutableDictionary dictionaryWithDictionary:attributeDict];
	
	if (namespaceURI && [namespaceURI length])
	{
		newElement.namespace = namespaceURI;
	}
	
	// if we don't have a root element yet, this is it
	if (!currentElement)
	{
		self.documentRoot = newElement;
		currentElement = documentRoot;
	}
	else
	{
		[currentElement.children addObject:newElement];
		newElement.parent = currentElement;
	}
		
	currentElement = newElement;
	[newElement release];  // still retained as documentRoot or a child
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[currentElement.text appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"VBoxView"])
	{
		NSLog(@"%@", [currentElement path]);
		NSLog(@"%@", currentElement );
	}
	
	currentElement = currentElement.parent;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	doneLoading = YES;
	
	NSLog(@"parse error: %@", [parseError localizedDescription]);

	if (delegate && [delegate respondsToSelector:@selector(xmlDocument:didFailWithError:)])
	{
		[delegate xmlDocument:self didFailWithError:parseError];
	}
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
	doneLoading = YES;

	if (delegate && [delegate respondsToSelector:@selector(xmlDocument:didFailWithError:)])
	{
		[delegate xmlDocument:self didFailWithError:validationError];
	}
}

- (void)parser:(NSXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI
{
	if (!namespaces)
	{
		namespaces = [[NSMutableDictionary dictionary] retain];
	}
	
	[namespaces setObject:namespaceURI forKey:prefix];
}

#pragma mark URL Loading
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// could be redirections, so we set the Length to 0 every time
	[receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[receivedData release];
	receivedData = nil;

	
	doneLoading = YES;

	if (delegate && [delegate respondsToSelector:@selector(xmlDocument:didFailWithError:)])
	{
		[delegate xmlDocument:self didFailWithError:error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:receivedData] autorelease];	
	[receivedData release];	
	receivedData = nil;
	
	[parser setShouldProcessNamespaces: YES];
	[parser setShouldReportNamespacePrefixes:YES];
	[parser setShouldResolveExternalEntities:NO];
	[parser setDelegate:self];
	
	doneLoading = YES;

	if ([parser parse])
	{
		
		if (delegate && [delegate respondsToSelector:@selector(xmlDocumentDidFinish:)])
		{
			[delegate  xmlDocumentDidFinish:self];
		}
	}
	
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge previousFailureCount] == 0) 
	{
		NSURLCredential *newCredential;
		
		if (delegate && [delegate respondsToSelector:@selector(userCredentialForAuthenticationChallenge:)])
		{
			newCredential = [delegate userCredentialForAuthenticationChallenge:challenge];
			
			if (newCredential)
			{
				[[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
			}
			else
			{
				[[challenge sender] cancelAuthenticationChallenge:challenge];
			}

		}
		else 
		{
			[[challenge sender] cancelAuthenticationChallenge:challenge];
		}

	} 
	else 
	{
		[[challenge sender] cancelAuthenticationChallenge:challenge];
	}
}

#pragma mark External methods
- (void) cancelLoading
{
	doneLoading = YES;

	[theConnection cancel];  // this cancels, no further callbacks
}

#pragma mark Misc
- (NSString *)description
{
	return [documentRoot description];
	
}

- (id) performActionOnElements:(SEL)selector target:(id<NSObject>)aTarget
{
	// first on documentRoot
	
	[documentRoot performActionOnElements:selector target:aTarget];
	
	return nil;
}
	

@end
