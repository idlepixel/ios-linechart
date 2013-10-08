//
//  MRLegendView.h
//  ios-linechart
//
//  Created by Marcel Ruegenberg on 02.08.13.
//  Copyright (c) 2013 Marcel Ruegenberg. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MRLegendView : UIView

@property (nonatomic, strong) UIFont *titlesFont;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSDictionary *colors; // maps titles to UIColors

@end
