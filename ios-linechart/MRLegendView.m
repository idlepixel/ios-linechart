//
//  MRLegendView.m
//  ios-linechart
//
//  Created by Marcel Ruegenberg on 02.08.13.
//  Copyright (c) 2013 Marcel Ruegenberg. All rights reserved.
//

#import "MRLegendView.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation MRLegendView

#define COLORPADDING    15.0f
#define PADDING         5.0f

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(c, [[UIColor colorWithWhite:0.0f alpha:0.1f] CGColor]);
    CGPathRef roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:7.0f].CGPath;
    CGContextAddPath(c, roundedRectPath);
    CGContextDrawPath(c, kCGPathFill);
    
    CGFloat y = 0.0f;
    for (NSString *title in self.titles) {
        UIColor *color = [self.colors objectForKey:title];
        if (color) {
            [color setFill];
            CGContextFillEllipseInRect(c, CGRectMake(PADDING + 2.0f, PADDING + round(y) + self.titlesFont.xHeight / 2.0f + 1.0f, 6.0f, 6.0f));
        }
        [[UIColor whiteColor] set];
        [title drawAtPoint:CGPointMake(COLORPADDING + PADDING, y + PADDING + 1.0f) withFont:self.titlesFont];
        [[UIColor blackColor] set];
        [title drawAtPoint:CGPointMake(COLORPADDING + PADDING, y + PADDING) withFont:self.titlesFont];
        y += [self.titlesFont lineHeight];
    }
}

- (UIFont *)titlesFont
{
    if(_titlesFont == nil) {
        _titlesFont = [UIFont boldSystemFontOfSize:10.0f];
    }
    return _titlesFont;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat h = [self.titlesFont lineHeight] * [self.titles count];
    CGFloat w = 0.0f;
    for (NSString *title in self.titles) {
        CGSize s = [title sizeWithFont:self.titlesFont];
        w = MAX(w, s.width);
    }
    return CGSizeMake(COLORPADDING + w + 2.0f * PADDING, h + 2.0f * PADDING);
}

@end
