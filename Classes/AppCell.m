//
//  AppCell.m
//  ASiST
//
//  Created by Oliver Drobnik on 12.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import "AppCell.h"
#import "App.h"
#import "MyAppSalesAppDelegate.h"
#import "Report_v1.h"
#import "YahooFinance.h"
#import "BadgeView.h"
#import <QuartzCore/QuartzCore.h>


@implementation AppCell

@synthesize app;

#define LEFT_COLUMN_OFFSET 75.0
#define RIGHT_MARGIN 10.0
#define VERTICAL_MARGIN 8.0
#define MAIN_FONT_SIZE 14.0


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = TABLEVIEWCELL_PLAIN_INIT) 
	{
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		appTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		//appTitleLabel.backgroundColor = [UIColor clearColor];  // otherwise it's in a white box
		appTitleLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE + 4.0];
		appTitleLabel.shadowColor = [UIColor whiteColor];
		appTitleLabel.shadowOffset = CGSizeMake(0, 1);
		[self.contentView addSubview:appTitleLabel];
		
		UIFont *smallerFont = [UIFont systemFontOfSize:14.0];
		UIColor *darkColor = [UIColor colorWithRed:58.0/256.0 green:58.0/256.0 blue:58.0/256.0 alpha:1.0];
		//UIColor *darkShadowColor = [UIColor colorWithRed:145.0/256.0 green:145.0/256.0 blue:145.0/256.0 alpha:1.0];
		
		
		subTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		subTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		//subTextLabel.backgroundColor = [UIColor clearColor];
		subTextLabel.textColor = darkColor; //[UIColor colorWithWhite:0.3 alpha:1.0];
		//subTextLabel.shadowColor = darkShadowColor;
		//subTextLabel.shadowOffset = CGSizeMake(1, 1);
		subTextLabel.adjustsFontSizeToFitWidth = YES;
		subTextLabel.font = smallerFont;
		[self.contentView addSubview:subTextLabel];
		
		
		royaltiesLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		royaltiesLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
		royaltiesLabel.backgroundColor = [UIColor clearColor];
		royaltiesLabel.textColor = darkColor; //[UIColor colorWithWhite:0.3 alpha:1.0];
		//royaltiesLabel.shadowColor = darkShadowColor;
		//royaltiesLabel.shadowOffset = CGSizeMake(1, 1);
		royaltiesLabel.adjustsFontSizeToFitWidth = YES;
		royaltiesLabel.textAlignment = UITextAlignmentRight;
		royaltiesLabel.font = smallerFont;
		[self.contentView addSubview:royaltiesLabel];
		
		totalUnitsLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		totalUnitsLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
		totalUnitsLabel.backgroundColor = [UIColor clearColor];
		totalUnitsLabel.textColor = darkColor; //[UIColor colorWithWhite:0.3 alpha:1.0];
		//totalUnitsLabel.shadowColor = darkShadowColor;
		//totalUnitsLabel.shadowOffset = CGSizeMake(1, 1);
		totalUnitsLabel.adjustsFontSizeToFitWidth = YES;
		totalUnitsLabel.font = smallerFont;
		[self.contentView addSubview:totalUnitsLabel];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyCache:) name:@"EmptyCache" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appReviewsUpdated:) name:@"AppReviewsUpdated" object:nil];
		
		badge = [[BadgeView alloc] initWithFrame:CGRectMake(40, 5, 40, 30)];
		//badge.center = CGPointMake(60, 60);
		[self addSubview:badge];  //naughty: we want to be above the standard imageview
		
		
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	
	CGFloat lineHeight = (contentRect.size.height - VERTICAL_MARGIN*2.0)/3.0;
	
	appTitleLabel.frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, contentRect.origin.y + VERTICAL_MARGIN,  contentRect.size.width -  LEFT_COLUMN_OFFSET - RIGHT_MARGIN, lineHeight);
	subTextLabel.frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, contentRect.origin.y+lineHeight + VERTICAL_MARGIN,  contentRect.size.width -  LEFT_COLUMN_OFFSET - RIGHT_MARGIN, lineHeight);
	CGFloat width = (contentRect.size.width -  LEFT_COLUMN_OFFSET - RIGHT_MARGIN - 5.0);
	royaltiesLabel.frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET + width*0.6, contentRect.origin.y+2.0*lineHeight + VERTICAL_MARGIN,  width*0.4, lineHeight);
	totalUnitsLabel.frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, contentRect.origin.y+2.0*lineHeight + VERTICAL_MARGIN,  width*0.6, lineHeight);
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[royaltiesLabel release];
	[totalUnitsLabel release];
	[appTitleLabel release];
	[subTextLabel release];
	[app release];
	
    [super dealloc];
}


- (App *)app
{
	return app;
}

- (void)setBackgroundColor:(UIColor *)newColor
{
	[super setBackgroundColor:newColor];
	appTitleLabel.backgroundColor = newColor;
	royaltiesLabel.backgroundColor = newColor;
	totalUnitsLabel.backgroundColor = newColor;
	subTextLabel.backgroundColor = newColor;
}

- (void)setBadge
{
	if (app.countNewReviews)
	{
		badge.text = [NSString stringWithFormat:@"%d", app.countNewReviews];
		CGRect frame = badge.frame;
		frame.origin.x = 74.0 - frame.size.width;
		badge.frame = frame;
		badge.hidden = NO;
	}
	else
	{
		badge.hidden = YES;
	}
}

- (void) showDisclosureIndicatorIfNeeded
{
	// show disclosure indicator if there are reviews
	
	// always show for now, we don't want to trigger loading of reviews
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	
	
	/*
	 if ([app.reviews count])
	 {
	 self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	 }
	 else
	 {
	 self.accessoryType = UITableViewCellAccessoryNone;
	 }
	 */
}

- (void)setApp:(App *)inApp
{
	//if (self.app != inApp)  // would prevent update for main currency change
	{
		[app release];
		app = [inApp retain];
		
		appTitleLabel.text = app.title;
		
		double converted = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:app.averageRoyaltiesPerDay fromCurrency:@"EUR"];
		subTextLabel.text = [NSString stringWithFormat:@"%@ per day", [[YahooFinance sharedInstance]  formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:converted]];
		
		double royalties_converted = [[YahooFinance sharedInstance] convertToCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:app.totalRoyalties fromCurrency:@"EUR"];
		if (royalties_converted)
		{
			royaltiesLabel.text = [NSString stringWithFormat:@"%0@", [[YahooFinance sharedInstance] formatAsCurrency:[[YahooFinance sharedInstance] mainCurrency] amount:royalties_converted]];
			totalUnitsLabel.text = [NSString stringWithFormat:@"%d sold", app.totalUnits];
		}
		else
		{
			royaltiesLabel.text = @"free";
			totalUnitsLabel.text = [NSString stringWithFormat:@"%d downloaded", app.totalUnits];
		}
		
		[self setBadge];
		
		
		
		if (app.iconImage)
		{
			self.CELL_IMAGE = app.iconImage;
		}
		else
		{
			self.CELL_IMAGE = [UIImage imageNamed:@"Empty.png"];
		}
		
		
		[self showDisclosureIndicatorIfNeeded];
		
	}
}

#pragma mark Notifications
- (void)emptyCache:(NSNotification *) notification
{
	self.CELL_IMAGE = nil;
}

- (void)appReviewsUpdated:(NSNotification *)notifications
{
	[self setBadge];
	[self showDisclosureIndicatorIfNeeded];
	
	//[self setNeedsDisplay];
}

@end
