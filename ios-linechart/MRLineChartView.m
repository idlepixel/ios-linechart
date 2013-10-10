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
@property (nonatomic, assign, readwrite) float x; // should be within the x range
@property (nonatomic, assign, readwrite) float y; // should be within the y range
@property (nonatomic, strong, readwrite) NSString *xLabel; // label to be shown on the x axis
@property (nonatomic, strong, readwrite) NSString *dataLabel; // label to be shown directly at the data item

- (id)initWithhX:(float)x y:(float)y xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel;

@end

@implementation MRLineChartDataItem

- (id)initWithhX:(float)x y:(float)y xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel
{
    if ((self = [super init])) {
        self.x = x;
        self.y = y;
        self.xLabel = xLabel;
        self.dataLabel = dataLabel;
        self.index = NSNotFound;
    }
    return self;
}

+ (MRLineChartDataItem *)dataItemWithX:(float)x y:(float)y xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel
{
    return [[MRLineChartDataItem alloc] initWithhX:x y:y xLabel:xLabel dataLabel:dataLabel];
}

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

@end



@interface MRLineChartView ()

@property (nonatomic, strong) MRLegendView *legendView;
@property (nonatomic, strong) MRInfoView *infoView;
@property (nonatomic, strong) UIView *currentPosView;
@property (nonatomic, strong) UILabel *xAxisLabel;

@end


#define X_AXIS_SPACE 15.0f
#define PADDING 10.0f


@implementation MRLineChartView

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
    
    self.currentPosView = [[UIView alloc] initWithFrame:CGRectMake(PADDING, PADDING, 4.0f, 50.0f)];
    self.currentPosView.backgroundColor = self.currentPositionColor;
    self.currentPosView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.currentPosView.alpha = 0.0;
    [self addSubview:self.currentPosView];
    
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

- (void)showLegend:(BOOL)show animated:(BOOL)animated
{
    if (!animated) {
        self.legendView.alpha = show ? 1.0f : 0.0f;
        return;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.legendView.alpha = show ? 1.0f : 0.0f;
    }];
}
                           
- (void)layoutSubviews
{
    [self.legendView sizeToFit];
    CGRect r = self.legendView.frame;
    r.origin.x = self.frame.size.width - self.legendView.frame.size.width - 3.0f - PADDING;
    r.origin.y = 3.0f + PADDING;
    self.legendView.frame = r;
    
    r = self.currentPosView.frame;
    CGFloat h = self.frame.size.height;
    r.size.height = h - 2.0f * PADDING - X_AXIS_SPACE;
    self.currentPosView.frame = r;
    
    [self.xAxisLabel sizeToFit];
    r = self.xAxisLabel.frame;
    r.origin.y = self.frame.size.height - X_AXIS_SPACE - PADDING + 2.0f;
    self.xAxisLabel.frame = r;
    
    [self bringSubviewToFront:self.legendView];
}

- (void)setData:(NSArray *)data
{
    if (data != _data) {
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
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    CGFloat availableHeight = self.bounds.size.height - 2.0f * PADDING - X_AXIS_SPACE;
    
    CGFloat yAxisLabelsWidth = [self yAxisLabelsWidth];
    
    CGFloat availableWidth = self.bounds.size.width - 2.0f * PADDING - yAxisLabelsWidth;
    CGFloat xStart = PADDING + yAxisLabelsWidth;
    CGFloat yStart = PADDING;
    
    CGFloat dashedPattern[] = {self.gridDashOnLength,self.gridDashOffLength};
    
    // draw scale and horizontal lines
    CGFloat heightPerStep = self.ySteps == nil || [self.ySteps count] == 0 ? availableHeight : (availableHeight / ([self.ySteps count] - 1));
    
    NSUInteger i = 0;
    CGContextSaveGState(c);
    CGContextSetLineWidth(c, self.gridLineWidth);
    NSUInteger yCnt = [self.ySteps count];
    for (NSString *step in self.ySteps) {
        CGFloat y = yStart + heightPerStep * (yCnt - 1.0f - i);
        if (!self.yAxisLabelHidden) {
            if (self.yAxisLabelColor) {
                [self.yAxisLabelColor set];
                CGFloat h = [self.scaleFont lineHeight];
                [step drawInRect:CGRectMake(yStart, y - h / 2.0f, yAxisLabelsWidth - 6.0f, h) withFont:self.scaleFont lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentRight];
            }
        }
        
        if (self.gridLineColor) {
            [self.gridLineColor set];
            CGContextSetLineDash(c, 0.0f, dashedPattern, 2);
            CGContextMoveToPoint(c, xStart, round(y) + 0.5f);
            CGContextAddLineToPoint(c, self.bounds.size.width - PADDING, round(y) + 0.5f);
            CGContextStrokePath(c);
        }
        i++;
    }
    
    NSUInteger xCnt = self.xStepsCount;
    if (xCnt > 1) {
        CGFloat widthPerStep = availableWidth / (xCnt - 1.0f);
        
        for (NSUInteger i = 0; i < xCnt; ++i) {
            NSLog(@"i: %d x: %d", i, xCnt);
            CGFloat x = xStart + widthPerStep * (xCnt - 1.0f - (CGFloat)i);
            
            if (self.gridLineColor) {
                [self.gridLineColor set];
                CGContextMoveToPoint(c, round(x) + 0.5f, PADDING);
                CGContextAddLineToPoint(c, round(x) + 0.5f, yStart + availableHeight);
                CGContextStrokePath(c);
            }
        }
    }
    
    CGContextRestoreGState(c);
    
    BOOL dataDrawn = NO;
    
    CGFloat yRangeLen = self.yMax - self.yMin;
    for (MRLineChartDataSeries *dataSeries in self.data) {
        // draw chart lines
        if (!dataSeries.lineHidden) {
            dataDrawn = YES;
            float xRangeLen = dataSeries.xMax - dataSeries.xMin;
            if(dataSeries.itemCount >= 2) {
                MRLineChartDataItem *dataItem = [dataSeries dataItemAtIndex:0];
                
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, NULL,
                                  xStart + round(((dataItem.x - dataSeries.xMin) / xRangeLen) * availableWidth),
                                  yStart + round((1.0f - (dataItem.y - self.yMin) / yRangeLen) * availableHeight));
                for(NSUInteger i = 1; i < dataSeries.itemCount; ++i) {
                    dataItem = [dataSeries dataItemAtIndex:i];
                    CGPathAddLineToPoint(path, NULL,
                                         xStart + round(((dataItem.x - dataSeries.xMin) / xRangeLen) * availableWidth),
                                         yStart + round((1.0f - (dataItem.y - self.yMin) / yRangeLen) * availableHeight));
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
            float xRangeLen = dataSeries.xMax - dataSeries.xMin;
            
            CGFloat outerRadius = dataSeries.pointRadius;
            CGFloat innerRadius = MAX(outerRadius - dataSeries.pointLineWidth, 0.0f);
            CGFloat padRadius = outerRadius + kPaddingWidth;
            CGFloat outerDiameter = outerRadius * 2.0f;
            CGFloat innerDiameter = innerRadius * 2.0f;
            CGFloat padDiameter = padRadius * 2.0f;
            MRLineChartDataItem *dataItem = nil;
            for(NSUInteger i = 0; i < dataSeries.itemCount; ++i) {
                dataItem = [dataSeries dataItemAtIndex:i];
                CGFloat xVal = xStart + round((xRangeLen == 0.0f ? 0.5f : ((dataItem.x - dataSeries.xMin) / xRangeLen)) * availableWidth);
                CGFloat yVal = yStart + round((1.0f - (dataItem.y - self.yMin) / yRangeLen) * availableHeight);
                [self.backgroundColor setFill];
                CGContextFillEllipseInRect(c, CGRectMake(xVal - padRadius, yVal - padRadius, padDiameter, padDiameter));
                [dataSeries.pointColor setFill];
                CGContextFillEllipseInRect(c, CGRectMake(xVal - outerRadius, yVal - outerRadius, outerDiameter, outerDiameter));
                [self.backgroundColor setFill];
                CGContextFillEllipseInRect(c, CGRectMake(xVal - innerRadius, yVal - innerRadius, innerDiameter, innerDiameter));
            } // for
        } // draw data points
    }
    
    if (!dataDrawn) {
        NSLog(@"You configured LineChartView to draw neither lines nor data points. No data will be visible. This is most likely not what you wanted. (But we aren't judging you, so here's your chart background.)");
    } // warn if no data was drawn
}

- (void)showIndicatorForTouch:(UITouch *)touch
{
    if (! self.infoView) {
        self.infoView = [[MRInfoView alloc] init];
        [self addSubview:self.infoView];
    }
    
    CGFloat yAxisLabelsWidth = [self yAxisLabelsWidth];
    
    CGPoint pos = [touch locationInView:self];
    CGFloat xStart = PADDING + yAxisLabelsWidth;
    CGFloat yStart = PADDING;
    CGFloat yRangeLen = self.yMax - self.yMin;
    CGFloat xPos = pos.x - xStart;
    CGFloat yPos = pos.y - yStart;
    CGFloat availableWidth = self.bounds.size.width - 2.0f * PADDING - yAxisLabelsWidth;
    CGFloat availableHeight = self.bounds.size.height - 2.0f * PADDING - X_AXIS_SPACE;
    
    MRLineChartDataSeries *closestSeries = nil;
    MRLineChartDataItem *closestItem = nil;
    CGPoint minimumDistance = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGPoint closestPos = CGPointZero;
    
    CGPoint distance = CGPointZero;
    MRLineChartDataItem *dataItem = nil;
    
    for (MRLineChartDataSeries *dataSeries in self.data) {
        float xRangeLen = dataSeries.xMax - dataSeries.xMin;
        for (NSUInteger i = 0; i < dataSeries.itemCount; ++i) {
            dataItem = [dataSeries dataItemAtIndex:i];
            CGFloat xVal = round((xRangeLen == 0.0f ? 0.5f : ((dataItem.x - dataSeries.xMin) / xRangeLen)) * availableWidth);
            CGFloat yVal = round((1.0f - (dataItem.y - self.yMin) / yRangeLen) * availableHeight);
            
            distance.x = fabsf(xVal - xPos);
            distance.y = fabsf(yVal - yPos);
            if (distance.x < minimumDistance.x || (distance.x == minimumDistance.x && distance.y < minimumDistance.y)) {
                minimumDistance.x = distance.x;
                minimumDistance.y = distance.y;
                closestItem = dataItem;
                closestSeries = dataSeries;
                closestPos = CGPointMake(xStart + xVal - 3.0f, yStart + yVal - 7.0f);
            }
        }
    }
    
    self.infoView.infoLabel.text = closestItem.dataLabel;
    self.infoView.tapPoint = closestPos;
    [self.infoView sizeToFit];
    [self.infoView setNeedsLayout];
    [self.infoView setNeedsDisplay];
    
    if (self.currentPosView.alpha == 0.0f) {
        CGRect r = self.currentPosView.frame;
        r.origin.x = closestPos.x + 3.0f - 1.0f;
        self.currentPosView.frame = r;
    }
    
    [UIView animateWithDuration:0.1f animations:^{
        self.infoView.alpha = 1.0f;
        self.currentPosView.alpha = 1.0f;
        self.xAxisLabel.alpha = 1.0f;
        
        CGRect r = self.currentPosView.frame;
        r.origin.x = closestPos.x + 3.0f - 1.0f;
        self.currentPosView.frame = r;
        
        self.xAxisLabel.text = closestItem.xLabel;
        if(self.xAxisLabel.text != nil) {
            [self.xAxisLabel sizeToFit];
            r = self.xAxisLabel.frame;
            r.origin.x = round(closestPos.x - r.size.width / 2.0f);
            self.xAxisLabel.frame = r;
        }
    }];
}

- (void)hideIndicator
{
    [UIView animateWithDuration:0.1f animations:^{
        self.infoView.alpha = 0.0f;
        self.currentPosView.alpha = 0.0f;
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

// TODO: This should really be a cached value. Invalidated iff ySteps changes.
- (CGFloat)yAxisLabelsWidth
{
    if (self.yAxisLabelHidden) {
        return 0.0f;
    } else {
        NSNumber *requiredWidth = [[self.ySteps mapWithBlock:^id(id obj) {
            NSString *label = (NSString*)obj;
            CGSize labelSize = [label sizeWithFont:self.scaleFont];
            return @(labelSize.width); // Literal NSNumber Conversion
        }] valueForKeyPath:@"@max.self"]; // gets biggest object. Yeah, NSKeyValueCoding. Deal with it.
        return [requiredWidth floatValue] + PADDING;
    }
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
        self.currentPosView.backgroundColor = currentPositionColor;
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
        CGRect frame = self.currentPosView.frame;
        CGFloat widthDelta = (CGRectGetWidth(frame) - currentPositionWidth)/2.0f;
        frame = CGRectInset(frame, widthDelta, 0.0f);
        self.currentPosView.frame = frame;
    }
}

@end
