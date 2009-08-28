//
//  DayReportCell.h
//  ASiST
//
//  Created by Oliver on 26.08.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CalendarDayView;


@interface DayReportCell : UITableViewCell 
{
	CalendarDayView *dayView;
	
	UILabel	*unitsSoldLabel;
	UILabel	*royaltyEarnedLabel;
	UILabel	*unitsUpdatedLabel;
}

@property (nonatomic, retain) CalendarDayView *dayView;
@property (nonatomic, retain) UILabel *unitsSoldLabel;
@property (nonatomic, retain) UILabel *royaltyEarnedLabel;
@property (nonatomic, retain) UILabel *unitsUpdatedLabel;

@end
