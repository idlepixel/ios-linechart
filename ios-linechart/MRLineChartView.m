//
//  MRLineChartView.m
//  
//
//  Created by Marcel Ruegenberg on 02.08.13.
//
//

#import "MRLineChartView.h"
#import "MRLegendView.h"
#import "MRInfoView.h"

#define kPaddingWidth           1.5f
#define kPaddingWidthDouble     (kPaddingWidth * 2.0f)

//
// NSArray (ArrayFP) category copied from
// https://github.com/mruegenberg/objc-utils
//

@interface NSArray (ArrayFP)

- (NSArray *)mapWithBlock:(id (^)(id obj))block;

@end

@implementation NSArray (ArrayFP)

- (NSArray *)mapWithBlock:(id (^)(id obj))block
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for(id val in self) {
        id mappedVal = block(val);
        if(mappedVal)
            [result addObject:mappedVal];
    }
    return result;
}

@end

@interface MRLineChartDataItem ()

@property (nonatomic, assign, readwrite) NSUInteger index;
@property (nonatomic, assign, readwrite) CGPoint position; // should be within the x & y ranges
@property (nonatomic, strong, readwrite) NSString *xLabel; // label to be shown on the x axis
@property (nonatomic, strong, readwrite) NSString *dataLabel; // label to be shown directly at the data item

- (id)initWithPosition:(CGPoint)position xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel;

@end

@implementation MRLineChartDataItem

- (id)initWithPosition:(CGPoint)position xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel
{
    if ((self = [super init])) {
        self.position = position;
        self.xLabel = xLabel;
        self.dataLabel = dataLabel;
        self.index = NSNotFound;
    }
    return self;
}

+ (MRLineChartDataItem *)dataItemWithPosition:(CGPoint)position xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel;
{
    return [[MRLineChartDataItem alloc] initWithPosition:position xLabel:xLabel dataLabel:dataLabel];
}

@end

@interface MRLineChartDataSeries ()

@property (nonatomic, assign) CGFloat xRange;

@end


@implementation MRLineChartDataSeries

-(id)init
{
    self = [super init];
    if (self) {
        self.lineWidth = 2.0f;
        self.pointRadius = 4.0f;
        self.pointLineWidth = 2.0f;
    }
    return self;
}

-(MRLineChartDataItem *)dataItemAtIndex:(NSUInteger)index
{
    if (index < self.itemCount && self.getData != nil) {
        MRLineChartDataItem *item = self.getData(index);
        item.index = index;
        return item;
    } else {
        return nil;
    }
}

-(void)setXMin:(CGFloat)xMin
{
    _xMin = xMin;
    self.xRange = self.xMax - xMin;
}

-(void)setXMax:(CGFloat)xMax
{
    _xMax = xMax;
    self.xRange = xMax - self.xMin;
}

@end



@interface MRLineChartView ()

@property (nonatomic, strong) MRLegendView *legendView;
@property (nonatomic, strong) MRInfoView *infoView;
@property (nonatomic, strong) UIView *currentPositionView;
@property (nonatomic, strong) UILabel *xAxisLabel;

@property (nonatomic, strong) MRLineChartDataSeries *lastSelectedDataSeries;
@property (nonatomic, assign) NSUInteger lastSelectedDataItemIndex;

@property (readonly) CGFloat xAxisLabelHeight;
@property (nonatomic, assign) CGFloat yAxisLabelWidth;

@property (nonatomic, assign) CGFloat yRange;

@property (nonatomic, assign) BOOL chartFrameBaked;

@end


#define X_AXIS_SPACE 15.0f
#define PADDING 10.0f


@implementation MRLineChartView
@synthesize chartFrame=_chartFrame;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.gridLineColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    self.xAxisLabelColor = [UIColor grayColor];
    self.yAxisLabelColor = [UIColor grayColor];
    self.currentPositionColor = [UIColor colorWithRed:0.7f green:0.0f blue:0.0f alpha:1.0f];
    
    self.gridLineWidth = 1.0f;
    self.gridDashOnLength = 4.0f;
    self.gridDashOffLength = 2.0f;
    
    self.currentPositionView = [[UIView alloc] initWithFrame:CGRectMake(PADDING, PADDING, 4.0f, 50.0f)];
    self.currentPositionView.backgroundColor = self.currentPositionColor;
    self.currentPositionView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.currentPositionView.alpha = 0.0;
    [self addSubview:self.currentPositionView];
    
    self.currentPositionWidth = 1.0f;
    
    self.legendView = [[MRLegendView alloc] initWithFrame:CGRectMake(self.frame.size.width - 50.0f - 10.0f, 10.0f, 50.0f, 30.0f)];
    self.legendView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.legendView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.legendView];
    
    self.xAxisLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 20.0f)];
    self.xAxisLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.xAxisLabel.font = [UIFont boldSystemFontOfSize:10.0f];
    self.xAxisLabel.textColor = [UIColor grayColor];
    self.xAxisLabel.textAlignment = NSTextAlignmentCenter;
    self.xAxisLabel.alpha = 0.0f;
    self.xAxisLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.xAxisLabel];
    
    self.backgroundColor = [UIColor whiteColor];
    self.scaleFont = [UIFont systemFontOfSize:10.0f];
    
    self.autoresizesSubviews = YES;
    self.contentMode = UIViewContentModeRedraw;
}

- (void)setView:(UIView *)view hidden:(BOOL)hidden animated:(BOOL)animated
{
    if (view == nil) return;
    
    if (!animated) {
        view.hidden = hidden;
    } else {
        if (!hidden && view.hidden) {
            view.alpha = 0.0f;
            view.hidden = NO;
        }
        [UIView animateWithDuration:0.3f animations:^{
            view.alpha = hidden ? 0.0f : 1.0f;
        } completion:^(BOOL finished){
            if (hidden) view.hidden = YES;
        }];
    }
}

- (void)setLegendHidden:(BOOL)hidden
{
    [self setLegendHidden:hidden animated:NO];
}

- (void)setLegendHidden:(BOOL)hidden animated:(BOOL)animated
{
    _legendHidden = hidden;
    [self setView:self.legendView hidden:hidden animated:animated];
}

- (void)setCurrentPositionHidden:(BOOL)hidden
{
    [self setCurrentPositionHidden:hidden animated:NO];
}

- (void)setCurrentPositionHidden:(BOOL)hidden animated:(BOOL)animated
{
    _currentPositionHidden = hidden;
    [self setView:self.currentPositionView hidden:hidden animated:animated];
}

- (void)setInfoHidden:(BOOL)hidden
{
    [self setInfoHidden:hidden animated:NO];
}

- (void)setInfoHidden:(BOOL)hidden animated:(BOOL)animated
{
    _infoHidden = hidden;
    [self setView:self.infoView hidden:hidden animated:animated];
}

- (void)setXAxisLabelHidden:(BOOL)hidden
{
    _xAxisLabelHidden = hidden;
    if (!hidden && self.xAxisLabel.hidden) {
        self.xAxisLabel.alpha = 0.0f;
    }
    self.xAxisLabel.hidden = hidden;
}

- (void)layoutSubviews
{
    CGFloat xAxisLabelHeight = [self xAxisLabelHeight];
    
    [self.legendView sizeToFit];
    CGRect r = self.legendView.frame;
    r.origin.x = self.frame.size.width - self.legendView.frame.size.width - 3.0f - PADDING;
    r.origin.y = 3.0f + PADDING;
    self.legendView.frame = r;
    
    r = self.currentPositionView.frame;
    CGFloat h = self.frame.size.height;
    r.size.height = h - 2.0f * PADDING - xAxisLabelHeight;
    self.currentPositionView.frame = r;
    
    [self.xAxisLabel sizeToFit];
    r = self.xAxisLabel.frame;
    r.origin.y = self.frame.size.height - xAxisLabelHeight - PADDING + 2.0f;
    self.xAxisLabel.frame = r;
    
    [self bringSubviewToFront:self.legendView];
}

- (void)setData:(NSArray *)data
{
    if (data != _data) {
        if (data.count > 0) {
            data = [NSArray arrayWithArray:data];
        } else {
            data = nil;
        }
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[data count]];
        NSMutableDictionary *colors = [NSMutableDictionary dictionaryWithCapacity:[data count]];
        for (MRLineChartDataSeries *series in data) {
            if (series.title) {
                [titles addObject:series.title];
                if (series.pointColor && !series.pointsHidden) {
                    [colors setObject:series.pointColor forKey:series.title];
                } else if (series.lineColor != nil && !series.lineHidden) {
                    [colors setObject:series.lineColor forKey:series.title];
                }
            }
        }
        self.legendView.titles = titles;
        self.legendView.colors = colors;
        
        _data = data;
        
        [self calculateLabelDimensions];
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    self.chartFrameBaked = YES;
    
    CGRect chartFrame = self.chartFrame;
    
    CGFloat dashedPattern[] = {self.gridDashOnLength,self.gridDashOffLength};
    
    // draw scale and horizontal lines
    CGFloat heightPerStep = self.ySteps == nil || [self.ySteps count] == 0 ? chartFrame.size.height : (chartFrame.size.height / ([self.ySteps count] - 1));
    
    NSUInteger i = 0;
    CGContextSaveGState(c);
    CGContextSetLineWidth(c, self.gridLineWidth);
    NSUInteger yCnt = [self.ySteps count];
    for (NSString *step in self.ySteps) {
        CGFloat y = chartFrame.origin.y + heightPerStep * (yCnt - 1.0f - i);
        if (!self.yAxisLabelHidden) {
            if (self.yAxisLabelColor) {
                [self.yAxisLabelColor set];
                CGFloat h = [self.scaleFont lineHeight];
                [step drawInRect:CGRectMake(PADDING, y - h / 2.0f, chartFrame.origin.x - PADDING * 2.0f, h) withFont:self.scaleFont lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentRight];
            }
        }
        
        if (self.gridLineColor) {
            [self.gridLineColor set];
            CGContextSetLineDash(c, 0.0f, dashedPattern, 2);
            CGContextMoveToPoint(c, chartFrame.origin.x, round(y) + 0.5f);
            CGContextAddLineToPoint(c, CGRectGetMaxX(chartFrame), round(y) + 0.5f);
            CGContextStrokePath(c);
        }
        i++;
    }
    
    NSUInteger xCnt = self.xStepsCount;
    if (xCnt > 1) {
        CGFloat widthPerStep = chartFrame.size.width / (xCnt - 1.0f);
        
        for (NSUInteger i = 0; i < xCnt; ++i) {
            NSLog(@"i: %d x: %d", i, xCnt);
            CGFloat x = chartFrame.origin.x + widthPerStep * (xCnt - 1.0f - (CGFloat)i);
            
            if (self.gridLineColor) {
                [self.gridLineColor set];
                CGContextMoveToPoint(c, round(x) + 0.5f, PADDING);
                CGContextAddLineToPoint(c, round(x) + 0.5f, chartFrame.origin.y + chartFrame.size.height);
                CGContextStrokePath(c);
            }
        }
    }
    
    CGContextRestoreGState(c);
    
    BOOL dataDrawn = NO;
    
    for (MRLineChartDataSeries *dataSeries in self.data) {
        // draw chart lines
        if (!dataSeries.lineHidden) {
            dataDrawn = YES;
            if(dataSeries.itemCount >= 2) {
                MRLineChartDataItem *dataItem = [dataSeries dataItemAtIndex:0];
                
                CGPoint position = [self convertDataItemPopositionToViewPosition:dataItem.position forDataSeries:dataSeries];
                
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, NULL, position.x, position.y);
                for(NSUInteger i = 1; i < dataSeries.itemCount; ++i) {
                    dataItem = [dataSeries dataItemAtIndex:i];
                    position = [self convertDataItemPopositionToViewPosition:dataItem.position forDataSeries:dataSeries];
                    CGPathAddLineToPoint(path, NULL, position.x, position.y);
                }
                
                CGContextAddPath(c, path);
                CGContextSetStrokeColorWithColor(c, [self.backgroundColor CGColor]);
                CGContextSetLineWidth(c, (dataSeries.lineWidth + kPaddingWidthDouble));
                CGContextStrokePath(c);
                
                CGContextAddPath(c, path);
                CGContextSetStrokeColorWithColor(c, [dataSeries.lineColor CGColor]);
                CGContextSetLineWidth(c, dataSeries.lineWidth);
                CGContextStrokePath(c);
                
                CGPathRelease(path);
            }
        }
        // draw chart points
        if (!dataSeries.pointsHidden) {
            dataDrawn = YES;
            
            CGFloat outerRadius = dataSeries.pointRadius;
            CGFloat innerRadius = MAX(outerRadius - dataSeries.pointLineWidth, 0.0f);
            CGFloat padRadius = outerRadius + kPaddingWidth;
            CGFloat outerDiameter = outerRadius * 2.0f;
            CGFloat innerDiameter = innerRadius * 2.0f;
            CGFloat padDiameter = padRadius * 2.0f;
            
            CGPoint position;
            
            MRLineChartDataItem *dataItem = nil;
            for(NSUInteger i = 0; i < dataSeries.itemCount; ++i) {
                dataItem = [dataSeries dataItemAtIndex:i];
                position = [self convertDataItemPopositionToViewPosition:dataItem.position forDataSeries:dataSeries];
                [self.backgroundColor setFill];
                CGContextFillEllipseInRect(c, CGRectMake(position.x - padRadius, position.y - padRadius, padDiameter, padDiameter));
                [dataSeries.pointColor setFill];
                CGContextFillEllipseInRect(c, CGRectMake(position.x - outerRadius, position.y - outerRadius, outerDiameter, outerDiameter));
                [self.backgroundColor setFill];
                CGContextFillEllipseInRect(c, CGRectMake(position.x - innerRadius, position.y - innerRadius, innerDiameter, innerDiameter));
            } // for
        } // draw data points
    }
    
    self.chartFrameBaked = NO;
    
    if (!dataDrawn) {
        NSLog(@"You configured LineChartView to draw neither lines nor data points. No data will be visible. This is most likely not what you wanted. (But we aren't judging you, so here's your chart background.)");
    } // warn if no data was drawn
}

- (void)notifyDelegateOfSelectedItem:(MRLineChartDataItem *)dataItem inSeries:(MRLineChartDataSeries *)dataSeries
{
    if (dataItem != nil && dataSeries != nil && (dataSeries != self.lastSelectedDataSeries || dataItem.index != self.lastSelectedDataItemIndex)) {
        if ([self.delegate respondsToSelector:@selector(lineChartView:didSelectItem:inSeries:)]) {
            [self.delegate lineChartView:self didSelectItem:dataItem inSeries:dataSeries];
        }
    }
    self.lastSelectedDataSeries = dataSeries;
    self.lastSelectedDataItemIndex = dataItem.index;
}

- (void)notifyDelegateOfClearedSelection
{
    if ([self.delegate respondsToSelector:@selector(lineChartViewDidClearSelection:)]) {
        [self.delegate lineChartViewDidClearSelection:self];
    }
    self.lastSelectedDataSeries = nil;
    self.lastSelectedDataItemIndex = NSNotFound;
}

- (void)showIndicatorForTouch:(UITouch *)touch
{
    if (!self.infoView) {
        self.infoView = [[MRInfoView alloc] init];
        [self addSubview:self.infoView];
        self.infoHidden = self.infoHidden;
    }
    
    self.chartFrameBaked = YES;
    
    CGRect chartFrame = self.chartFrame;
    
    CGPoint touchPosition = [touch locationInView:self];
    
    MRLineChartDataSeries *closestSeries = nil;
    MRLineChartDataItem *closestItem = nil;
    CGPoint minimumDistance = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGPoint closestPos = CGPointZero;
    
    CGPoint dataItemPosition;
    CGPoint distance = CGPointZero;
    MRLineChartDataItem *dataItem = nil;
    
    for (MRLineChartDataSeries *dataSeries in self.data) {
        for (NSUInteger i = 0; i < dataSeries.itemCount; ++i) {
            dataItem = [dataSeries dataItemAtIndex:i];
            
            dataItemPosition = [self convertDataItemPopositionToViewPosition:dataItem.position forDataSeries:dataSeries];
            
            distance.x = fabsf(dataItemPosition.x - touchPosition.x);
            distance.y = fabsf(dataItemPosition.y - touchPosition.y);
            if (distance.x < minimumDistance.x || (distance.x == minimumDistance.x && distance.y < minimumDistance.y)) {
                minimumDistance.x = distance.x;
                minimumDistance.y = distance.y;
                closestItem = dataItem;
                closestSeries = dataSeries;
                closestPos = CGPointMake(dataItemPosition.x - 3.0f, dataItemPosition.y - 7.0f);
            }
        }
    }
    
    self.chartFrameBaked = NO;
    
    [self notifyDelegateOfSelectedItem:closestItem inSeries:closestSeries];
    
    self.infoView.infoLabel.text = closestItem.dataLabel;
    self.infoView.tapPoint = closestPos;
    [self.infoView sizeToFit];
    [self.infoView setNeedsLayout];
    [self.infoView setNeedsDisplay];
    
    if (self.currentPositionView.alpha == 0.0f) {
        CGRect r = self.currentPositionView.frame;
        r.origin.x = closestPos.x + 3.0f - 1.0f;
        self.currentPositionView.frame = r;
    }
    
    [UIView animateWithDuration:0.1f animations:^{
        self.infoView.alpha = 1.0f;
        self.currentPositionView.alpha = 1.0f;
        self.xAxisLabel.alpha = 1.0f;
        
        CGRect r = self.currentPositionView.frame;
        r.origin.x = closestPos.x + 3.0f - 1.0f;
        self.currentPositionView.frame = r;
        
        if (!self.xAxisLabelHidden) {
            self.xAxisLabel.text = closestItem.xLabel;
            if(self.xAxisLabel.text != nil) {
                [self.xAxisLabel sizeToFit];
                r = self.xAxisLabel.frame;
                r.origin.x = round(closestPos.x - r.size.width / 2.0f);
                self.xAxisLabel.frame = r;
            }
        }
    }];
}

- (void)hideIndicator
{
    [self notifyDelegateOfClearedSelection];
    
    [UIView animateWithDuration:0.1f animations:^{
        self.infoView.alpha = 0.0f;
        self.currentPositionView.alpha = 0.0f;
        self.xAxisLabel.alpha = 0.0f;
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self showIndicatorForTouch:[touches anyObject]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self showIndicatorForTouch:[touches anyObject]];	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self hideIndicator];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self hideIndicator];
}

#pragma mark Helper methods

- (void)calculateLabelDimensions
{
    NSNumber *requiredWidth = [[self.ySteps mapWithBlock:^id(id obj) {
        NSString *label = (NSString*)obj;
        CGSize labelSize = [label sizeWithFont:self.scaleFont];
        return @(labelSize.width); // Literal NSNumber Conversion
    }] valueForKeyPath:@"@max.self"]; // gets biggest object. Yeah, NSKeyValueCoding. Deal with it.
    _yAxisLabelWidth = [requiredWidth floatValue] + PADDING;
}

- (CGFloat)yAxisLabelsWidth
{
    if (self.yAxisLabelHidden) {
        return 0.0f;
    } else {
        return _yAxisLabelWidth;
    }
}

- (CGFloat)xAxisLabelHeight
{
    if (self.xAxisLabelHidden) {
        return 0.0f;
    } else {
        return X_AXIS_SPACE;
    }
}

-(void)setYMin:(CGFloat)yMin
{
    _yMin = yMin;
    self.yRange = self.yMax - yMin;
}

-(void)setYMax:(CGFloat)yMax
{
    _yMax = yMax;
    self.yRange = yMax - self.yMin;
}

- (CGRect)chartFrame
{
    if (!self.chartFrameBaked) {
        CGRect frame = self.bounds;
        frame.origin.x = PADDING + [self yAxisLabelsWidth];
        frame.origin.y = PADDING;
        frame.size.width = frame.size.width - (PADDING * 2.0f + [self yAxisLabelsWidth]);
        frame.size.height = frame.size.height - (PADDING * 2.0f + [self xAxisLabelHeight]);
        _chartFrame = frame;
    }
    return _chartFrame;
}

- (void)setChartFrameBaked:(BOOL)chartFrameBaked
{
    if (chartFrameBaked) {
        _chartFrameBaked = NO;
        [self chartFrame];
    }
    _chartFrameBaked = chartFrameBaked;
}

- (CGPoint)convertDataItemPopositionToViewPosition:(CGPoint)point forDataSeries:(MRLineChartDataSeries *)dataSeries
{
    CGPoint result = CGPointZero;
    CGRect chartFrame = self.chartFrame;
    result.x = round(chartFrame.origin.x + (dataSeries.xRange == 0.0f ? 0.5f : ((point.x - dataSeries.xMin) / dataSeries.xRange)) * CGRectGetWidth(chartFrame));
    result.y = round(chartFrame.origin.y + (1.0f - (point.y - self.yMin) / self.yRange) * CGRectGetHeight(chartFrame));
    return result;
}

#pragma mark - Appearance

-(void)setGridLineColor:(UIColor *)gridLineColor
{
    if (_gridLineColor == nil || [_gridLineColor isEqual:gridLineColor]) {
        _gridLineColor = gridLineColor;
        [self setNeedsDisplay];
    }
}

-(void)setCurrentPositionColor:(UIColor *)currentPositionColor
{
    if (_currentPositionColor == nil || [_currentPositionColor isEqual:currentPositionColor]) {
        _currentPositionColor = currentPositionColor;
        self.currentPositionView.backgroundColor = currentPositionColor;
    }
}

-(void)setXAxisLabelColor:(UIColor *)xAxisLabelColor
{
    if (_xAxisLabelColor == nil || [_xAxisLabelColor isEqual:xAxisLabelColor]) {
        _xAxisLabelColor = xAxisLabelColor;
        [self setNeedsDisplay];
    }
}

-(void)setYAxisLabelColor:(UIColor *)yAxisLabelColor
{
    if (_yAxisLabelColor == nil || [_yAxisLabelColor isEqual:yAxisLabelColor]) {
        _yAxisLabelColor = yAxisLabelColor;
        [self setNeedsDisplay];
    }
}

-(void)setGridLineWidth:(CGFloat)gridLineWidth
{
    if (_gridLineWidth != gridLineWidth) {
        _gridLineWidth = gridLineWidth;
        [self setNeedsDisplay];
    }
}

-(void)setGridDashOnLength:(CGFloat)gridDashOnLength
{
    if (_gridDashOnLength != gridDashOnLength) {
        _gridDashOnLength = gridDashOnLength;
        [self setNeedsDisplay];
    }
}

-(void)setGridDashOffLength:(CGFloat)gridDashOffLength
{
    if (_gridDashOffLength != gridDashOffLength) {
        _gridDashOffLength = gridDashOffLength;
        [self setNeedsDisplay];
    }
}

-(void)setCurrentPositionWidth:(CGFloat)currentPositionWidth
{
    if (_currentPositionWidth != currentPositionWidth) {
        _currentPositionWidth = currentPositionWidth;
        CGRect frame = self.currentPositionView.frame;
        CGFloat widthDelta = (CGRectGetWidth(frame) - currentPositionWidth)/2.0f;
        frame = CGRectInset(frame, widthDelta, 0.0f);
        self.currentPositionView.frame = frame;
    }
}

@end
