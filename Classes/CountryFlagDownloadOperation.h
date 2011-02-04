//
//  CountryFlagDownloadOperation.h
//  ASiST
//
//  Created by Oliver on 28.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CountryFlagDownloadOperation : NSOperation 
{
	NSString *_iso3;
}

@property (nonatomic, retain) NSString *iso3;

- (id)initWithISO3:(NSString *)iso3;

@end
