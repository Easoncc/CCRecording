//
//  TUDrawingView.h
//  tataufo
//
//  Created by chenchao on 2016/12/13.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TUDrawingView : UIView

@property (nonatomic ,strong) UIColor *lineColor;
@property (nonatomic ,assign) float lineWidth;

- (void)removeLastLine;
- (int)getLineCount;

@end
