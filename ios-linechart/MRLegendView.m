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

#define COLORPADDING 15
#define PADDING 5

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(c, [[UIColor colorWithWhite:0.0 alpha:0.1] CGColor]);
    CGPathRef roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:7.0f].CGPath;
    CGContextAddPath(c, roundedRectPath);
    CGContextDrawPath(c, kCGPathFill);
    
    CGFloat y = 0;
    for (NSString *title in self.titles) {
        UIColor *color = [self.colors objectForKey:title];
        if (color) {
            [color setFill];
            CGContextFillEllipseInRect(c, CGRectMake(PADDING + 2, PADDING + round(y) + self.titlesFont.xHeight / 2 + 1, 6, 6));
        }
        [[UIColor whiteColor] set];
        [title drawAtPoint:CGPointMake(COLORPADDING + PADDING, y + PADDING + 1) withFont:self.titlesFont];
        [[UIColor blackColor] set];
        [title drawAtPoint:CGPointMake(COLORPADDING + PADDING, y + PADDING) withFont:self.titlesFont];
        y += [self.titlesFont lineHeight];
    }
}

- (UIFont *)titlesFont
{
    if(_titlesFont == nil) {
        _titlesFont = [UIFont boldSystemFontOfSize:10];
    }
    return _titlesFont;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat h = [self.titlesFont lineHeight] * [self.titles count];
    CGFloat w = 0;
    for (NSString *title in self.titles) {
        CGSize s = [title sizeWithFont:self.titlesFont];
        w = MAX(w, s.width);
    }
    return CGSizeMake(COLORPADDING + w + 2 * PADDING, h + 2 * PADDING);
}

@end
