//
//  AppIconDownloadOperation.h
//  ASiST
//
//  Created by Oliver on 29.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AppIconDownloadOperation : NSOperation 
{
	NSInteger _appID;
	NSString *_appName;
}

@property (nonatomic, assign) NSInteger appID;
@property (nonatomic, retain) NSString *appName;

- (id)initWithApplicationIdentifier:(NSInteger)appID;

@end
