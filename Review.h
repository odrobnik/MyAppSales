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
@property (nonatomic, retain) NSString * reviewText;
@property (nonatomic, retain) NSString * version;
@property (nonatomic, retain) NSString * translatedReviewTitle;
@property (nonatomic, retain) NSNumber * stars;
@property (nonatomic, retain) NSString * translatedReviewText;
@property (nonatomic, retain) Product * app;
@property (nonatomic, retain) Country * country;

@end



