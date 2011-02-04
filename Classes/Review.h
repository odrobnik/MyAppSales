//
//  Review.h
//  ASiST
//
//  Created by Oliver on 12.05.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Country;
@class Product;

@interface Review :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * appVersion;
@property (nonatomic, retain) NSString * titleTranslated;
@property (nonatomic, retain) NSNumber * ratingPercent;
@property (nonatomic, retain) NSString * textTranslated;
@property (nonatomic, retain) Product * app;
@property (nonatomic, retain) Country * country;
@property (nonatomic, retain) NSNumber * isNew;
@property (nonatomic, retain) NSString * appUserVersionHash;

@end



