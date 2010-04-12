//
//  XMLelement.h
//
//  Created by Oliver on 02.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

@interface XMLelement : NSObject {
	NSString *name;
	NSString *namespace;
	NSMutableString *text;
	NSMutableArray *children;
	NSMutableDictionary *attributes;
	XMLelement *parent;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *namespace;
@property (nonatomic, retain) NSMutableString *text;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, retain) NSMutableDictionary *attributes;
@property (nonatomic, assign) XMLelement *parent;


- (id) initWithName:(NSString *)elementName;
- (XMLelement *) getNamedChild:(NSString *)childName;
- (NSArray *) getNamedChildren:(NSString *)childName WithAttribute:(NSString *)attributeName HasValue:(NSString *)attributeValue;
- (NSArray *) getNamedChildren:(NSString *)childName;
- (void) removeNamedChild:(NSString *)childName;
- (void) changeTextForNamedChild:(NSString *)childName toText:(NSString *)newText;
- (XMLelement *) addChildWithName:(NSString *)childName text:(NSString *)childText;

- (id) performActionOnElements:(SEL)selector target:(id)aTarget;

//- (NSArray *) subnodesForPath:(NSString *)path;

- (NSString *)path;


@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSURL *link;
@property (nonatomic, readonly) NSString *content;

@end
