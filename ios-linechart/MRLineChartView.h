//
//  MRLineChartView.h
//  
//
//  Created by Marcel Ruegenberg on 02.08.13.
//
//

#import <UIKit/UIKit.h>

@class MRLineChartDataItem;

typedef MRLineChartDataItem *(^MRLineChartDataGetter)(NSUInteger item);



@interface MRLineChartDataItem : NSObject

@property (nonatomic, assign, readonly) float x; // should be within the x range
@property (nonatomic, assign, readonly) float y; // should be within the y range
@property (nonatomic, strong, readonly) NSString *xLabel; // label to be shown on the x axis
@property (nonatomic, strong, readonly) NSString *dataLabel; // label to be shown directly at the data item

+ (MRLineChartDataItem *)dataItemWithX:(float)x y:(float)y xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel;

@end



@interface MRLineChartDataSeries : NSObject

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *pointColor;
@property (nonatomic, assign) CGFloat pointRadius;
@property (nonatomic, assign) CGFloat pointLineWidth;

@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSUInteger itemCount;

@property (nonatomic, assign) BOOL pointsHidden; // Switch to turn off circles on data points.
@property (nonatomic, assign) BOOL lineHidden; // Switch to turn off lines connecting data points.


@property (nonatomic, assign) float xMin;
@property (nonatomic, assign) float xMax;

@property (nonatomic, copy) MRLineChartDataGetter getData;

@end



@interface MRLineChartView : UIView

@property (nonatomic,retain) UIColor *gridLineColor UI_APPEARANCE_SELECTOR;
@property (nonatomic,retain) UIColor *currentPositionColor UI_APPEARANCE_SELECTOR;
@property (nonatomic,retain) UIColor *xAxisLabelColor UI_APPEARANCE_SELECTOR;
@property (nonatomic,retain) UIColor *yAxisLabelColor UI_APPEARANCE_SELECTOR;

@property (nonatomic,assign) CGFloat currentPositionWidth UI_APPEARANCE_SELECTOR;
@property (nonatomic,assign) CGFloat gridLineWidth UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) NSArray *data; // Array of `MRLineChartDataSeries` objects, one for each line.

@property (nonatomic, assign) BOOL yAxisLabelHidden;

@property (nonatomic, assign) float yMin;
@property (nonatomic, assign) float yMax;
@property (nonatomic, strong) NSArray *ySteps; // Array of step names (NSString). At each step, a scale line is shown.
@property (nonatomic, assign) NSUInteger xStepsCount; // number of steps in x. At each x step, a vertical scale line is shown. if x < 2, nothing is done

@property (nonatomic, strong) UIFont *scaleFont; // Font in which scale markings are drawn. Defaults to [UIFont systemFontOfSize:10].

- (void)showLegend:(BOOL)show animated:(BOOL)animated;

@end
