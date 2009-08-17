//
//  ChartView.h
//  ASiST
//
//  Created by Oliver Drobnik on 20.01.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ChartView : UIView {
	NSDictionary *myData;
	
	double max_chart_value;
	double bottom_inset;
	
	double column_width;
	
	NSDateFormatter *dateFormatterToRead;
}

@property (nonatomic, retain) NSDictionary *myData;

@property (nonatomic, assign) double max_chart_value;
@property (nonatomic, assign) double bottom_inset;
@property (nonatomic, assign) double column_width;



- (id)initWithChartData:(NSDictionary *)dict;

//- (id)initWithData:(NSDictionary *)dict Apps:(NSArray *)app_array Column:(NSString *)column;
//- (double) getMaxFromData;

- (void)setStrokeColorFromIndex:(NSInteger)idx context:(CGContextRef)context;
- (CGRect) chartDimensions;
-(void)drawView:(ChartView *)view inContext:(CGContextRef)context bounds:(CGRect)bounds;


@end
