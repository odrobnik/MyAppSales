//
//  Product+Custom.m
//  ASiST
//
//  Created by Oliver on 27.09.10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "Product+Custom.h"
#import "Review+Custom.h"
#import "CoreDatabase.h"
#import "SynchingManager.h"


@implementation Product (Custom)

- (UIImage *)iconImage
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];

	NSString *iconCachePath = [documentsDirectory stringByAppendingPathComponent:
							   [NSString stringWithFormat:@"%@.png", [self.appleIdentifier description]]];
	
	UIImage *retImage = [UIImage imageWithContentsOfFile:iconCachePath];
	
	if (!retImage)
	{
		retImage = [UIImage imageNamed:@"Empty.png"];
	}
	
	return retImage;
}

- (NSString *)reviewsAsHTML
{
	NSMutableString *tmpString = [NSMutableString string];
	
	NSSortDescriptor *desc = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	
	NSArray *sortedReviews = [self.reviews sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
	
	for (Review *oneReview in sortedReviews)
	{
		[tmpString appendString:[oneReview stringAsHTML]];
	}
	
	if ([tmpString length])
	{
		return [NSString stringWithString:tmpString];
	}
	else 
	{
		return @"<p>No reviews in Database</p>";
	}
}

- (void)increaseNewReviewCount
{
	NSInteger currentCount = [self.newReviewsCount intValue] + 1;
	self.newReviewsCount = [NSNumber numberWithInt:currentCount];
}

- (void) getAllReviews
{
	NSArray *countries = [[CoreDatabase sharedInstance] allCountriesWithAppStore];
	
	for (Country *oneCountry in countries)
	{
		[[SynchingManager sharedInstance] scrapeForProduct:self country:oneCountry delegate:(id)self];
	}
}

- (void) didFinishRetrievingReviews:(NSArray *)scrapedReviews
{
	self.lastReviewRefresh = [NSDate date];
	
	for (NSDictionary *reviewDict in scrapedReviews)
	{
		NSString *title = [reviewDict objectForKey:@"ReviewTitle"];
		NSString *text = [reviewDict objectForKey:@"ReviewText"];
		double rating = [[reviewDict objectForKey:@"Rating"] doubleValue];

		NSString *hash = [reviewDict objectForKey:@"Hash"];
		
		NSPredicate *hashPred = [NSPredicate predicateWithFormat:@"appUserVersionHash = %@", hash];
		
		Review *review = [[self.reviews filteredSetUsingPredicate:hashPred] anyObject];
		
		BOOL needsNewTranslation = NO;
		
		if (review)
		{
			// update existing review
			
			if (![title isEqualToString:review.title] ||
				![text isEqualToString:review.text] ||
				rating != [review.ratingPercent doubleValue])
			{
				review.title = title;
				
				if (![review.text isEqualToString:text])
				{
					needsNewTranslation = YES;
				}
				
				review.ratingPercent = [NSNumber numberWithDouble:rating];
				review.isNew = [NSNumber numberWithBool:YES];
			}
		}
		else 
		{
			// add new review
			
			review = (Review *)[NSEntityDescription insertNewObjectForEntityForName:@"Review" 
																	 inManagedObjectContext:[CoreDatabase sharedInstance].managedObjectContext];
			review.title = title;
			review.date = [reviewDict objectForKey:@"ReviewDate"];
			review.ratingPercent = [reviewDict objectForKey:@"Rating"];
			review.userName = [reviewDict objectForKey:@"UserName"];
			review.country = [[CoreDatabase sharedInstance] countryForCode:[reviewDict objectForKey:@"ISO2"]];
			review.appVersion = [reviewDict objectForKey:@"Version"];
			
			review.app = self;
			review.appUserVersionHash = hash;
			review.isNew = [NSNumber numberWithBool:YES];
			
			[self increaseNewReviewCount];
			
			needsNewTranslation = YES;
		}
		
		if (needsNewTranslation)
		{
			review.text = text;
			[[CoreDatabase sharedInstance] translateReview:review];
		}
	}
	
	[[CoreDatabase sharedInstance] save];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ id=%@ title=%@>", [self class],
			self.appleIdentifier, self.title];
}

@end


@end
