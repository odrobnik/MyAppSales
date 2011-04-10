//
//  XMLelement.m
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "XMLelement.h"
#import "NSString+Helpers.h"


@implementation XMLelement

@synthesize name, text, children, attributes, parent, namespace;


- (id) initWithName:(NSString *)elementName
{
	if ((self = [super init]))
	{
		self.name = elementName; 
		self.text = [NSMutableString string];
		//self.children = [NSMutableArray array];
	}
	
	return self;
}

- (void) dealloc
{
	[name release];
	[text release];
	[children release];
	[attributes release];
	
	[super dealloc];
}

static int indentLevel = 0;

// as XML
- (NSString *)description
{
	NSString *ns;
	
	if (namespace)
	{
		ns = [NSString stringWithFormat:@" xmlns=\"%@\"", namespace];
	}
	else 
	{
		ns = @"";
	}
	
	
	
	NSMutableString *indent = [NSMutableString string];
	
	for (int i=0; i<indentLevel; i++)
	{
		[indent appendString:@"\t"];
	}
	
	NSMutableString *attributeString = [NSMutableString string];
	
	for (NSString *oneAttribute in [attributes allKeys])
	{
		[attributeString appendFormat:@" %@=\"%@\"", oneAttribute, [[attributes objectForKey:oneAttribute] stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"]];
	}
	
	if ([children count])
	{
		NSMutableString *childrenString = [NSMutableString string];
		
		indentLevel ++;
		for (XMLelement *oneChild in children)
		{
			[childrenString appendFormat:@"%@", oneChild];
		}
		indentLevel --;
		
		return [NSString stringWithFormat:@"%@<%@%@%@>\n%@%@</%@>\n", indent, name, attributeString, ns, childrenString, indent, name];
	}
	else 
	{
		if (!text||![text length])
		{
			return [NSString stringWithFormat:@"%@<%@%@%@ />\n", indent, name, attributeString, ns];
		}
		else
		{
			return [NSString stringWithFormat:@"%@<%@%@%@>%@</%@>\n", indent, name, attributeString, ns, [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], name];
		}
		
	}
	
}

- (XMLelement *) getNamedChild:(NSString *)childName
{
	for (XMLelement *oneChild in self.children)
	{
		if ([oneChild.name isEqualToString:childName])
		{
			return oneChild;
		}
	}
	
	return nil;
}

- (NSArray *) getNamedChildren:(NSString *)childName
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (XMLelement *oneChild in self.children)
	{
		if ([oneChild.name isEqualToString:childName])
		{
			[tmpArray addObject:oneChild];
		}
	}
	
	if ([tmpArray count])
	{
		return [NSArray arrayWithArray:tmpArray]; // non-mutable
	}
	else
	{
		return nil;
	}
	
}

- (NSArray *) getNamedChildren:(NSString *)childName WithAttribute:(NSString *)attributeName HasValue:(NSString *)attributeValue
{
	NSMutableArray *retArray = [NSMutableArray array];
	
	// first get all Children with this name
	NSArray *foundChildren = [self getNamedChildren:childName];
	
	// all the fit the filter copy to retArray
	
	for (XMLelement *oneElement in foundChildren)
	{
		NSString *attrVal = [oneElement.attributes objectForKey:attributeName];
		
		if ([attrVal isEqualToString:attributeValue])
		{
			[retArray addObject:oneElement];
		}
	}
	
	
	if ([retArray count])
	{
		return [NSArray arrayWithArray:retArray];
	}
	else
	{
		return nil;
	}
}



- (void) removeNamedChild:(NSString *)childName
{
	XMLelement *childToDelete = [self getNamedChild:childName];
	[self.children removeObject:childToDelete];
}

- (void) changeTextForNamedChild:(NSString *)childName toText:(NSString *)newText
{
	XMLelement *childToModify = [self getNamedChild:childName];
	[childToModify.text setString:newText];
}



- (XMLelement *) addChildWithName:(NSString *)childName text:(NSString *)childText
{
	XMLelement *newChild = [[[XMLelement alloc] initWithName:childName] autorelease];
	if (childText)
	{
		newChild.text = [NSString stringWithString:childText];
	}
	newChild.parent = self;
	[self.children addObject:newChild];
	
	return newChild;
}



#pragma mark virtual properties
- (NSString *)title
{
	XMLelement *titleElement = [self getNamedChild:@"title"];
	return titleElement.text;
}

- (NSMutableDictionary *) attributes
{
	// make dictionary if we don't have one
	if (!attributes)
	{
		self.attributes = [NSMutableDictionary dictionary];
	}
	
	return attributes;
}

- (NSMutableArray *) children
{
	// make array if we don't have one
	if (!children)
	{
		self.children = [NSMutableArray array];
	}
	
	return children;
}


- (NSURL *)link
{
	XMLelement *linkElement = [self getNamedChild:@"link"];
	NSString *linkString = [linkElement.attributes objectForKey:@"href"];
	
	// workaround
	//linkString = [linkString stringByReplacingOccurrencesOfString:@"http://192.168.1.78:8080/ELO-AFS/app" withString:@"http://divos.dyndns.org:8080/afs-elo/afs"];
	
	return linkString?[NSURL URLWithString:linkString]:nil;
}

- (NSString *) content
{
	return [self valueForKey:@"content"];
}

- (id) valueForKey:(NSString *)key
{
	XMLelement *titleElement = [self getNamedChild:key];
	return titleElement.text;
}

- (id) performActionOnElements:(SEL)selector target:(id)aTarget
{
	// execute action for self
	//[aTarget performSelector:selector withObject:self];
	
	// now for all children
	for (XMLelement *oneChild in children)
	{
		[oneChild performActionOnElements:selector target:aTarget];
		[aTarget performSelector:selector withObject:oneChild];
	}
	
	return nil;
}

- (NSString *)path
{
	if (parent)
	{
		return [[parent path] stringByAppendingPathComponent:name];
	}
	else 
	{
		return [@"/" stringByAppendingPathComponent:name];
	}
}


/*
- (NSArray *) subnodesForPath:(NSString *)path
{
	if (!path)
	{
		return 
	
	NSScanner *scanner = [[NSScanner alloc] initWithString:path];
*/	
	
	
	
	
	
	
	


@end
