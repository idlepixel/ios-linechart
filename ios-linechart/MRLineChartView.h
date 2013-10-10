//
//  MRLineChartView.h
//  
//
//  Created by Marcel Ruegenberg on 02.08.13.
//
//

#import <UIKit/UIKit.h>

@class MRLineChartDataItem;
@class MRLineChartDataSeries;
@class MRLineChartView;

@protocol MRLineChartViewDelegate <NSObject>

@optional
- (void)lineChartView:(MRLineChartView *)view didSelectItem:(MRLineChartDataItem *)dataItem inSeries:(MRLineChartDataSeries *)dataSeries;
- (void)lineChartViewDidClearSelection:(MRLineChartView *)view;

@end

typedef MRLineChartDataItem *(^MRLineChartDataGetter)(NSUInteger item);



@interface MRLineChartDataItem : NSObject

@property (nonatomic, assign, readonly) NSUInteger index;
@property (nonatomic, assign, readonly) CGPoint position; // should be within the x & y ranges
@property (nonatomic, strong, readonly) NSString *xLabel; // label to be shown on the x axis
@property (nonatomic, strong, readonly) NSString *dataLabel; // label to be shown directly at the data item

+ (MRLineChartDataItem *)dataItemWithPosition:(CGPoint)position xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel;

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
@property (nonatomic,assign) CGFloat gridDashOnLength UI_APPEARANCE_SELECTOR;
@property (nonatomic,assign) CGFloat gridDashOffLength UI_APPEARANCE_SELECTOR;

@property (nonatomic, weak) id<MRLineChartViewDelegate> delegate;

@property (nonatomic, strong) NSArray *data; // Array of `MRLineChartDataSeries` objects, one for each line.

@property (nonatomic, assign) BOOL xAxisLabelHidden;
@property (nonatomic, assign) BOOL yAxisLabelHidden;

@property (nonatomic, assign) float yMin;
@property (nonatomic, assign) float yMax;
@property (nonatomic, strong) NSArray *ySteps; // Array of step names (NSString). At each step, a scale line is shown.
@property (nonatomic, assign) NSUInteger xStepsCount; // number of steps in x. At each x step, a vertical scale line is shown. if x < 2, nothing is done

@property (nonatomic, strong) UIFont *scaleFont; // Font in which scale markings are drawn. Defaults to [UIFont systemFontOfSize:10].

@property (nonatomic, assign) BOOL legendHidden;
@property (nonatomic, assign) BOOL currentPositionHidden;
@property (nonatomic, assign) BOOL infoHidden;

- (void)setLegendHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setCurrentPositionHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setInfoHidden:(BOOL)hidden animated:(BOOL)animated;

@end
