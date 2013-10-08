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
    }
    return self;
}

+ (MRLineChartDataItem *)dataItemWithX:(float)x y:(float)y xLabel:(NSString *)xLabel dataLabel:(NSString *)dataLabel
{
    return [[MRLineChartDataItem alloc] initWithhX:x y:y xLabel:xLabel dataLabel:dataLabel];
}

@end



@implementation MRLineChartData

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
    self.currentPosView = [[UIView alloc] initWithFrame:CGRectMake(PADDING, PADDING, 1.0f / self.contentScaleFactor, 50.0f)];
    self.currentPosView.backgroundColor = [UIColor colorWithRed:0.7f green:0.0f blue:0.0f alpha:1.0f];
    self.currentPosView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.currentPosView.alpha = 0.0;
    [self addSubview:self.currentPosView];
    
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
        for(MRLineChartData *dat in data) {
            [titles addObject:dat.title];
            [colors setObject:dat.pointColor forKey:dat.title];
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
    
    CGFloat availableWidth = self.bounds.size.width - 2.0f * PADDING - self.yAxisLabelsWidth;
    CGFloat xStart = PADDING + self.yAxisLabelsWidth;
    CGFloat yStart = PADDING;
    
    static CGFloat dashedPattern[] = {4.0f,2.0f};
    
    // draw scale and horizontal lines
    CGFloat heightPerStep = self.ySteps == nil || [self.ySteps count] == 0 ? availableHeight : (availableHeight / ([self.ySteps count] - 1));
    
    NSUInteger i = 0;
    CGContextSaveGState(c);
    CGContextSetLineWidth(c, 1.0f);
    NSUInteger yCnt = [self.ySteps count];
    for (NSString *step in self.ySteps) {
        [[UIColor grayColor] set];
        CGFloat h = [self.scaleFont lineHeight];
        CGFloat y = yStart + heightPerStep * (yCnt - 1.0f - i);
        [step drawInRect:CGRectMake(yStart, y - h / 2.0f, self.yAxisLabelsWidth - 6.0f, h) withFont:self.scaleFont lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentRight];
        
        [[UIColor colorWithWhite:0.9f alpha:1.0f] set];
        CGContextSetLineDash(c, 0.0f, dashedPattern, 2);
        CGContextMoveToPoint(c, xStart, round(y) + 0.5f);
        CGContextAddLineToPoint(c, self.bounds.size.width - PADDING, round(y) + 0.5f);
        CGContextStrokePath(c);
        
        i++;
    }
    
    NSUInteger xCnt = self.xStepsCount;
    if (xCnt > 1) {
        CGFloat widthPerStep = availableWidth / (xCnt - 1.0f);
        
        [[UIColor grayColor] set];
        for (NSUInteger i = 0; i < xCnt; ++i) {
            NSLog(@"i: %d x: %d", i, xCnt);
            CGFloat x = xStart + widthPerStep * (xCnt - 1.0f - (CGFloat)i);
            
            [[UIColor colorWithWhite:0.9f alpha:1.0f] set];
            CGContextMoveToPoint(c, round(x) + 0.5f, PADDING);
            CGContextAddLineToPoint(c, round(x) + 0.5f, yStart + availableHeight);
            CGContextStrokePath(c);
        }
    }
    
    CGContextRestoreGState(c);

    BOOL dataDrawn = NO;
    
    CGFloat yRangeLen = self.yMax - self.yMin;
    for (MRLineChartData *data in self.data) {
        if (!data.lineHidden) {
            dataDrawn = YES;
            float xRangeLen = data.xMax - data.xMin;
            if(data.itemCount >= 2) {
                MRLineChartDataItem *datItem = data.getData(0);
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, NULL,
                                  xStart + round(((datItem.x - data.xMin) / xRangeLen) * availableWidth),
                                  yStart + round((1.0f - (datItem.y - self.yMin) / yRangeLen) * availableHeight));
                for(NSUInteger i = 1; i < data.itemCount; ++i) {
                    MRLineChartDataItem *datItem = data.getData(i);
                    CGPathAddLineToPoint(path, NULL,
                                         xStart + round(((datItem.x - data.xMin) / xRangeLen) * availableWidth),
                                         yStart + round((1.0f - (datItem.y - self.yMin) / yRangeLen) * availableHeight));
                }
                
                CGContextAddPath(c, path);
                CGContextSetStrokeColorWithColor(c, [self.backgroundColor CGColor]);
                CGContextSetLineWidth(c, 5.0f);
                CGContextStrokePath(c);
                
                CGContextAddPath(c, path);
                CGContextSetStrokeColorWithColor(c, [data.lineColor CGColor]);
                CGContextSetLineWidth(c, 2.0f);
                CGContextStrokePath(c);
                
                CGPathRelease(path);
            }
        } // draw actual chart data
        if (!data.pointsHidden) {
            dataDrawn = YES;
            float xRangeLen = data.xMax - data.xMin;
            for(NSUInteger i = 0; i < data.itemCount; ++i) {
                MRLineChartDataItem *datItem = data.getData(i);
                CGFloat xVal = xStart + round((xRangeLen == 0.0f ? 0.5f : ((datItem.x - data.xMin) / xRangeLen)) * availableWidth);
                CGFloat yVal = yStart + round((1.0f - (datItem.y - self.yMin) / yRangeLen) * availableHeight);
                [self.backgroundColor setFill];
                CGContextFillEllipseInRect(c, CGRectMake(xVal - 5.5f, yVal - 5.5f, 11.0f, 11.0f));
                [data.pointColor setFill];
                CGContextFillEllipseInRect(c, CGRectMake(xVal - 4.0f, yVal - 4.0f, 8.0f, 8.0f));
                [[UIColor whiteColor] setFill];
                CGContextFillEllipseInRect(c, CGRectMake(xVal - 2.0f, yVal - 2.0f, 4.0f, 4.0f));
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
    
    CGPoint pos = [touch locationInView:self];
    CGFloat xStart = PADDING + self.yAxisLabelsWidth;
    CGFloat yStart = PADDING;
    CGFloat yRangeLen = self.yMax - self.yMin;
    CGFloat xPos = pos.x - xStart;
    CGFloat yPos = pos.y - yStart;
    CGFloat availableWidth = self.bounds.size.width - 2.0f * PADDING - self.yAxisLabelsWidth;
    CGFloat availableHeight = self.bounds.size.height - 2.0f * PADDING - X_AXIS_SPACE;
    
    MRLineChartDataItem *closest = nil;
    float minDist = FLT_MAX;
    float minDistY = FLT_MAX;
    CGPoint closestPos = CGPointZero;
    
    for (MRLineChartData *data in self.data) {
        float xRangeLen = data.xMax - data.xMin;
        for(NSUInteger i = 0; i < data.itemCount; ++i) {
            MRLineChartDataItem *datItem = data.getData(i);
            CGFloat xVal = round((xRangeLen == 0.0f ? 0.5f : ((datItem.x - data.xMin) / xRangeLen)) * availableWidth);
            CGFloat yVal = round((1.0f - (datItem.y - self.yMin) / yRangeLen) * availableHeight);
            
            float dist = fabsf(xVal - xPos);
            float distY = fabsf(yVal - yPos);
            if(dist < minDist || (dist == minDist && distY < minDistY)) {
                minDist = dist;
                minDistY = distY;
                closest = datItem;
                closestPos = CGPointMake(xStart + xVal - 3.0f, yStart + yVal - 7.0f);
            }
        }
    }
    
    self.infoView.infoLabel.text = closest.dataLabel;
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
        
        self.xAxisLabel.text = closest.xLabel;
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
    NSNumber *requiredWidth = [[self.ySteps mapWithBlock:^id(id obj) {
        NSString *label = (NSString*)obj;
        CGSize labelSize = [label sizeWithFont:self.scaleFont];
        return @(labelSize.width); // Literal NSNumber Conversion
    }] valueForKeyPath:@"@max.self"]; // gets biggest object. Yeah, NSKeyValueCoding. Deal with it.
    return [requiredWidth floatValue] + PADDING;
}

@end
