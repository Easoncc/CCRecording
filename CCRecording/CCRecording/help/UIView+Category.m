//
//  UIView+Category.m
//  tataufo
//
//  Created by XuWenqiang on 15/11/22.
//  Copyright © 2015年 tataufo. All rights reserved.
//

#import "UIView+Category.h"
//#import "STMacroAdaptation.h"

@implementation UIView (Category)

-(void)setX:(CGFloat)x{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

-(CGFloat)x{
    return self.frame.origin.x;
}

-(void)setY:(CGFloat)y{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

-(CGFloat)y{
    return self.frame.origin.y;
}

-(void)setCenterX:(CGFloat)centerX{
    CGPoint point = self.center;
    point.x = centerX;
    self.center = point;
}

-(CGFloat)centerX{
    return self.center.x;
}

- (void)setCenterY:(CGFloat)centerY
{
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (void)setSize:(CGSize)size
{
    //    self.width = size.width;
    //    self.height = size.height;
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGSize)size
{
    return self.frame.size;
}

#pragma mark - 2015/04/08

-(CGFloat)bottom
{
    return self.y + self.height;
}

- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - [self height];
    self.frame = frame;
    return;
}

- (CGFloat)right {
    return self.x + [self width];
}

- (void)setRight:(CGFloat)right {
    CGFloat delta = right - (self.frame.origin.x + self.frame.size.width);
    CGRect newframe = self.frame;
    newframe.origin.x += delta ;
    self.frame = newframe;
}

-(CGFloat)left
{
    return self.x;
}

-(void)setLeft:(CGFloat)left
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
    return;
}

-(void)setTop:(CGFloat)top{
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}

-(CGFloat)top{
    return self.frame.origin.y;
}

@end
