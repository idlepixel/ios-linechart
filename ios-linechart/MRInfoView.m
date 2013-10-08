//
//  MRInfoView.m
//  Classes
//
//  Created by Marcel Ruegenberg on 19.11.09.
//  Copyright 2009 Dustlab. All rights reserved.
//

#import "MRInfoView.h"


@interface MRInfoView ()

- (void)recalculateFrame;

@end


@implementation MRInfoView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {		
        UIFont *fatFont = [UIFont boldSystemFontOfSize:12.0f];
        
        self.infoLabel = [[UILabel alloc] init]; self.infoLabel.font = fatFont;
        self.infoLabel.backgroundColor = [UIColor clearColor]; self.infoLabel.textColor = [UIColor whiteColor];
        self.infoLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        self.infoLabel.shadowColor = [UIColor blackColor];
        self.infoLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
        self.infoLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.infoLabel];
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#define TOP_BOTTOM_MARGIN   5.0f
#define LEFT_RIGHT_MARGIN   15.0f
#define SHADOWSIZE          3.0f
#define SHADOWBLUR          5.0f
#define HOOK_SIZE           8.0f

void CGContextAddRoundedRectWithHookSimple(CGContextRef c, CGRect rect, CGFloat radius)
{
	//eventRect must be relative to rect.
	CGFloat hookSize = HOOK_SIZE;
	CGContextAddArc(c, rect.origin.x + radius, rect.origin.y + radius, radius, M_PI, M_PI * 1.5f, 0.0f); //upper left corner
	CGContextAddArc(c, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, radius, M_PI * 1.5f, M_PI * 2.0f, 0.0f); //upper right corner
	CGContextAddArc(c, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height - radius, radius, M_PI * 2.0f, M_PI * 0.5f, 0.0f);
    {
		CGContextAddLineToPoint(c, rect.origin.x + rect.size.width / 2.0f + hookSize, rect.origin.y + rect.size.height);
		CGContextAddLineToPoint(c, rect.origin.x + rect.size.width / 2.0f, rect.origin.y + rect.size.height + hookSize);
		CGContextAddLineToPoint(c, rect.origin.x + rect.size.width / 2.0f - hookSize, rect.origin.y + rect.size.height);
	}
	CGContextAddArc(c, rect.origin.x + radius, rect.origin.y + rect.size.height - radius, radius, M_PI * 0.5f, M_PI, 0.0f);
	CGContextAddLineToPoint(c, rect.origin.x, rect.origin.y + radius);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self sizeToFit];
    
    [self recalculateFrame];
    
    [self.infoLabel sizeToFit];
    self.infoLabel.frame = CGRectMake(self.bounds.origin.x + 7.0f, self.bounds.origin.y + 2.0f, self.infoLabel.frame.size.width, self.infoLabel.frame.size.height);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize s = [self.infoLabel.text sizeWithFont:self.infoLabel.font];
    s.height += 15.0f;
    s.height += SHADOWSIZE;
    
    s.width += 2.0f * SHADOWSIZE + 7.0f;
    s.width = MAX(s.width, HOOK_SIZE * 2.0f + 2.0f * SHADOWSIZE + 10.0f);
    
    return s;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef c = UIGraphicsGetCurrentContext();

	CGRect theRect = self.bounds;
	//passe x oder y Position sowie Hoehe oder Breite an, je nachdem, wo der Hook sitzt.
	theRect.size.height -= SHADOWSIZE * 2.0f;
	theRect.origin.x += SHADOWSIZE;
	theRect.size.width -= SHADOWSIZE * 2.0f;
    theRect.size.height -= SHADOWSIZE * 2.0f;
	
    [[UIColor colorWithWhite:0.0f alpha:1.0f] set];
	CGContextSetAlpha(c, 0.7f);

	CGContextSaveGState(c);
	
    CGContextSetShadow(c, CGSizeMake(0.0f, SHADOWSIZE), SHADOWBLUR);
	
	CGContextBeginPath(c);
    CGContextAddRoundedRectWithHookSimple(c, theRect, 7.0f);
	CGContextFillPath(c);
	
    [[UIColor whiteColor] set];
	theRect.origin.x += 1.0f;
	theRect.origin.y += 1.0f;
	theRect.size.width -= 2.0f;
	theRect.size.height = theRect.size.height / 2.0f + 1.0f;
	CGContextSetAlpha(c, 0.2f);
    
    CGPathRef roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:theRect cornerRadius:6.0f].CGPath;
    CGContextAddPath(c, roundedRectPath);
    CGContextDrawPath(c, kCGPathFill);
}



#define MAX_WIDTH   400.0f
// calculate own frame to fit within parent frame and be large enough to hold the event.
- (void)recalculateFrame
{
    CGRect theFrame = self.frame;
    theFrame.size.width = MIN(MAX_WIDTH, theFrame.size.width);
    
    CGRect theRect = self.frame; theRect.origin = CGPointZero;

    {
        theFrame.origin.y = self.tapPoint.y - theFrame.size.height + 2.0f * SHADOWSIZE + 1.0f;
        theFrame.origin.x = round(self.tapPoint.x - ((theFrame.size.width - 2.0f * SHADOWSIZE)) / 2.0f);
    }
    self.frame = theFrame;
}

@end
