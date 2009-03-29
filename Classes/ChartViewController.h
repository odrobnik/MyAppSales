//
//  ChartViewController.h
//  ASiST
//
//  Created by Oliver Drobnik on 20.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChartView, AxisView, LegendView;

@interface ChartViewController : UIViewController <UIScrollViewDelegate> {
	ChartView *myChart;
	AxisView *myAxis;
	LegendView *myLegend;
	UIScrollView *myScroll;
}

@property (nonatomic, retain) ChartView *myChart;
@property (nonatomic, retain) AxisView *myAxis;
@property (nonatomic, retain) LegendView *myLegend;
@property (nonatomic, retain) UIScrollView *myScroll;


//- (id)initWithDataDict:(NSDictionary *)dataDict apps:(NSArray *)apps appKeys:(NSArray *)appKeys column:(NSString *)column;
- (id)initWithChartData:(NSDictionary *)dataDict;

@end
