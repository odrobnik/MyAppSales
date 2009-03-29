//
//  AppCell.m
//  ASiST
//
//  Created by Oliver Drobnik on 12.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AppCell.h"
#import "App.h"
#import "ASiSTAppDelegate.h"
#import "BirneConnect.h"
#import "Report.h"
#import "YahooFinance.h"


@implementation AppCell

@synthesize app;

#define LEFT_COLUMN_OFFSET 75.0
#define MAIN_FONT_SIZE 14.0


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        // Initialization code
		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryNone;
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		appTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		appTitleLabel.backgroundColor = [UIColor clearColor];  // otherwise it's in a white box
		//unitsSoldLabel.opaque = NO;
		//unitsSoldLabel.textColor = [UIColor blackColor];
		//unitsSoldLabel.highlightedTextColor = [UIColor whiteColor];
		//unitsSoldLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		//appTitleLabel.textAlignment = UITextAlignmentCenter;
		appTitleLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE + 4.0];
		[self.contentView addSubview:appTitleLabel];
		
		// create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		subTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		subTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		subTextLabel.backgroundColor = [UIColor clearColor];
		subTextLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
		//royaltyEarnedLabel.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		subTextLabel.adjustsFontSizeToFitWidth = YES;
		//subTextLabel.textAlignment = UITextAlignmentCenter;
		[self.contentView addSubview:subTextLabel];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	
	//double column_width = (contentRect.size.width - LEFT_COLUMN_OFFSET - 10.0)/4.0;
	
	// In this example we will never be editing, but this illustrates the appropriate pattern
    CGRect frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, contentRect.origin.y+10.0, contentRect.size.width -  LEFT_COLUMN_OFFSET,  contentRect.size.height/2.0);
	appTitleLabel.frame = frame;
	
    frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, contentRect.size.height/2.0, contentRect.size.width -  LEFT_COLUMN_OFFSET,  contentRect.size.height/2.0-10.0);
	
	subTextLabel.frame = frame;
}

- (void)dealloc
{
	[appTitleLabel release];
	[subTextLabel release];
	[app release];
	
    [super dealloc];
}


- (App *)app
{
	return app;
}

- (void)setApp:(App *)inApp
{
	//if (self.app != inApp)  // would prevent update for main currency change
	{
		[app release];
		app = [inApp retain];
		
		appTitleLabel.text = app.title;
		[appTitleLabel setNeedsDisplay];
		
		ASiSTAppDelegate *appDelegate = (ASiSTAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		double converted = [appDelegate.itts.myYahoo convertToCurrency:appDelegate.itts.myYahoo.mainCurrency amount:app.averageRoyaltiesPerDay fromCurrency:@"EUR"];
		subTextLabel.text = [NSString stringWithFormat:@"%@/day for past 7 days", [appDelegate.itts.myYahoo formatAsCurrency:appDelegate.itts.myYahoo.mainCurrency amount:converted]];

	/*	
		Report *lastReportDay = [appDelegate.itts.latestReportsByType objectForKey:[NSNumber numberWithInt:ReportTypeDay]];
		Report *lastReportWeek = [appDelegate.itts.latestReportsByType objectForKey:[NSNumber numberWithInt:ReportTypeWeek]];
		
		NSInteger sumUnitsDay = [lastReportDay sumUnitsForAppId:[NSNumber numberWithInt:app.apple_identifier] transactionType:TransactionTypeSale];
		NSInteger sumUnitsWeek = [lastReportWeek sumUnitsForAppId:[NSNumber numberWithInt:app.apple_identifier] transactionType:TransactionTypeSale];
		NSInteger sumRoyaltiesDay = [lastReportDay sumRoyaltiesForAppId:[NSNumber numberWithInt:app.apple_identifier] transactionType:TransactionTypeSale];
		NSInteger sumRoyaltiesWeek = [lastReportWeek sumRoyaltiesForAppId:[NSNumber numberWithInt:app.apple_identifier] transactionType:TransactionTypeSale];
		
		
		double lastWeekUnitsAvg = sumUnitsWeek/7.0;
		double percentUnits = sumUnitsDay/lastWeekUnitsAvg;
		
		double lastWeekRoyaltiesAvg = sumRoyaltiesWeek/7.0;
		double percentRoyalties = sumRoyaltiesDay/lastWeekRoyaltiesAvg;
		
		NSString *trendUnits;
		
		if (percentUnits>1.0)
		{
			trendUnits = [NSString stringWithFormat:@"%+0.2f%%", 100.0*(percentUnits-1.0)];
		}
		else
		{
			trendUnits = [NSString stringWithFormat:@"-%0.2f%%", 100.0*(1.0-percentUnits)];
		}
		
		NSString *trendRoyalties;
		
		if (percentRoyalties>1.0)
		{
			trendRoyalties = [NSString stringWithFormat:@"%+0.2f%%", 100.0*(percentRoyalties-1.0)];
		}
		else
		{
			trendRoyalties = [NSString stringWithFormat:@"-%0.2f%%", 100.0*(1.0-percentRoyalties)];
		}
		
	subTextLabel.text = [NSString stringWithFormat:@"# %@, $ %@",trendUnits, trendRoyalties];
*/		
		
		if (app.iconImage)
		{
			self.image = app.iconImage;
		}
		else
		{
			self.image = [UIImage imageNamed:@"Empty.png"];
		}
	}
}

@end
