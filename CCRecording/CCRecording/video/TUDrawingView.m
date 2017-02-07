//
//  TUDrawingView.m
//  tataufo
//
//  Created by chenchao on 2016/12/13.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUDrawingView.h"

@interface Line : NSObject

@property (nonatomic ,assign) CGPoint begin;
@property (nonatomic ,assign) CGPoint end;
@property (nonatomic ,assign) float width;
@property (nonatomic ,strong) UIColor *color;

@end
@implementation Line
@end
@interface TUDrawingView()

@property (nonatomic ,strong) NSMutableArray *lineSegmentArray;

@end

@implementation TUDrawingView{
    NSMutableArray *_lineArray;
    Line *_currentLine;
}

- (int)getLineCount{
    return (int)_lineSegmentArray.count;
}

- (void)removeLastLine{
    [_lineSegmentArray removeLastObject];
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _lineSegmentArray = [NSMutableArray new];
    
    }
    return self;
}

//  It is a method of UIView called every time the screen needs a redisplay or refresh.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context,kCGLineJoinRound);
    
    [_lineColor set];
    
    for (NSArray *array in _lineSegmentArray) {
        for (Line *line in array) {
            [[line color] set];
            CGContextBeginPath(context);
            CGContextSetLineWidth(context, line.width);
            CGContextMoveToPoint(context, [line begin].x, [line begin].y);
            CGContextAddLineToPoint(context, [line end].x, [line end].y);
            CGContextStrokePath(context);
        }
    }
    
    for (Line *line in _lineArray) {
        [[line color] set];
        CGContextBeginPath(context);
        CGContextSetLineWidth(context, line.width);
        CGContextMoveToPoint(context, [line begin].x, [line begin].y);
        CGContextAddLineToPoint(context, [line end].x, [line end].y);
        CGContextStrokePath(context);
    }
}

- (void)addLine:(Line*)line{
    [_lineArray addObject:line];
}

- (void)removeLine:(Line*)line
{
    if ([_lineArray containsObject:line])
        [_lineArray removeObject:line];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    _lineArray = [NSMutableArray new];
    UITouch* touch=[touches anyObject];
    CGPoint loc = [touch locationInView:self];
    
    Line *newLine = [[Line alloc] init];
    newLine.begin = loc;
    newLine.end = loc;
    newLine.width = _lineWidth;
    newLine.color =_lineColor;
    _currentLine = newLine;

    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    UITouch* touch=[[touches allObjects] firstObject];
    CGPoint loc = [touch locationInView:self];
    
    _currentLine.color = _lineColor;
    _currentLine.end = loc;
    _currentLine.width = _lineWidth;
    
    if (_currentLine) {
        [self addLine:_currentLine];
    }
    Line *newLine = [[Line alloc] init];
    newLine.begin = loc;
    newLine.end = loc;
    newLine.width = _lineWidth;
    newLine.color =_lineColor;
    _currentLine = newLine;
    
    [self setNeedsDisplay];


}

- (void)endTouches:(NSSet *)touches
{
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    [_lineSegmentArray addObject:_lineArray];
    _lineArray = nil;
    [self endTouches:touches];

    
}

@end
