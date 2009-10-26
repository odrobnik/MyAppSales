//
//  CalendarDayView.h
//  ASiST
//
//  Created by Oliver on 25.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CalendarDayView : UIView 
{
	
	UILabel *weekdayLabel;
	UILabel *dayLabel;
	
	NSDate *date;
	
}



@property (nonatomic, retain) UILabel *weekdayLabel;
@property (nonatomic, retain) UILabel *dayLabel;
@property (nonatomic, retain) NSDate *date;

@end
