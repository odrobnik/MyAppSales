//
//  AppCell.m
//  ASiST
//
//  Created by Oliver Drobnik on 12.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
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
#define RIGHT_MARGIN 10.0
#define VERTICAL_MARGIN 8.0
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
		appTitleLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE + 4.0];
		[self.contentView addSubview:appTitleLabel];

		UIFont *smallerFont = [UIFont systemFontOfSize:14.0];
		
		subTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		subTextLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		subTextLabel.backgroundColor = [UIColor clearColor];
		subTextLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
		subTextLabel.adjustsFontSizeToFitWidth = YES;
		subTextLabel.font = smallerFont;
		[self.contentView addSubview:subTextLabel];
		
		
		royaltiesLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		royaltiesLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
		royaltiesLabel.backgroundColor = [UIColor clearColor];
		royaltiesLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
		royaltiesLabel.adjustsFontSizeToFitWidth = YES;
		royaltiesLabel.textAlignment = UITextAlignmentRight;
		royaltiesLabel.font = smallerFont;
		[self.contentView addSubview:royaltiesLabel];
		
		totalUnitsLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		totalUnitsLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
		totalUnitsLabel.backgroundColor = [UIColor clearColor];
		totalUnitsLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
		totalUnitsLabel.adjustsFontSizeToFitWidth = YES;
		totalUnitsLabel.font = smallerFont;
		[self.contentView addSubview:totalUnitsLabel];
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
	royaltiesLabel.frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, contentRect.origin.y+2.0*lineHeight + VERTICAL_MARGIN,  contentRect.size.width -  LEFT_COLUMN_OFFSET - RIGHT_MARGIN, lineHeight);
	totalUnitsLabel.frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, contentRect.origin.y+2.0*lineHeight + VERTICAL_MARGIN,  contentRect.size.width -  LEFT_COLUMN_OFFSET - RIGHT_MARGIN, lineHeight);
}

- (void)dealloc
{
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
			totalUnitsLabel.text = [NSString stringWithFormat:@"%d sold", app.totalUnitsSold];
		}
		else
		{
			royaltiesLabel.text = @"free";
			totalUnitsLabel.text = [NSString stringWithFormat:@"%d downloaded", app.totalUnitsSold];
		}
		
		
		
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
