//
//  TUVideoTextImageView.m
//  tataufo
//
//  Created by chenchao on 2016/12/14.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUVideoTextImageView.h"


//#define pi 3.14159265358979323846
#define degreesToRadian(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI)

@implementation TUVideoTextImageView{
    float _currentAngle;
    float _currentScale;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentAngle = 10000;
        _currentScale = 10000;
        self.scale = 1;
        self.userInteractionEnabled = YES;
        
//        //捏合
//        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
//        [self addGestureRecognizer:pinch];
//        //旋转
//        UIRotationGestureRecognizer *rotation = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationView:)];
//        [self addGestureRecognizer:rotation];
        //拖动
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
        pan.minimumNumberOfTouches = 1;
        pan.maximumNumberOfTouches = 2;
        [self addGestureRecognizer:pan];
        //点击
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapView:)];
        [self addGestureRecognizer:tap];
        
        
    }
    return self;
}

#pragma mark --- UITapGestureRecognizer 轻拍手势事件 ---
-(void)tapView:(UITapGestureRecognizer *)sender{
    if ([self.delegate respondsToSelector:@selector(tapImageToEdit:)]) {
        [self.delegate tapImageToEdit:self];
    }
}
#pragma mark pan   平移手势事件
-(void)panView:(UIPanGestureRecognizer *)sender{
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        if ([self.delegate respondsToSelector:@selector(panBeginPointdSender:)]) {
            [self.delegate panBeginPointdSender:self];
        }
        
        if (sender.numberOfTouches == 2) {
            CGPoint p1;
            CGPoint p2;
            p1 = [sender locationOfTouch:0 inView:self.superview];
            p2 = [sender locationOfTouch:1 inView:self.superview];
            
            float angle = [self angleBetweenPoints:p2 andPoint:p1];
            
            _currentAngle = angle;
            
        }else{
            _currentAngle = 10000;
            _currentScale = 10000;
        }
        
    }else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [sender translationInView:self];
        CGPoint pointsuper = [sender locationInView:self.superview.superview];
        //    NSLog(@"superpoint :%f %f",pointsuper.x,pointsuper.y);
        
        sender.view.transform = CGAffineTransformTranslate(sender.view.transform, point.x, point.y);
        
        self.offsetPoint = CGPointMake(self.offsetPoint.x+point.x, self.offsetPoint.y+point.y);
        
        //增量置为o
        [sender setTranslation:CGPointZero inView:sender.view];
        
        if ([self.delegate respondsToSelector:@selector(panMovePoint:andSender:)]) {
            [self.delegate panMovePoint:pointsuper andSender:self];
        }
        
        CGPoint p1;
        CGPoint p2;
        if (sender.numberOfTouches == 2) {
            
            p1 = [sender locationOfTouch:0 inView:self.superview];
            p2 = [sender locationOfTouch:1 inView:self.superview];
            
            float angle = [self angleBetweenPoints:p2 andPoint:p1];
            
            if (_currentAngle != 10000) {
                
                float chaju =  angle - _currentAngle;
                
                if (chaju < -4 && _currentAngle > M_PI_2*3) {
                    chaju = angle+M_PI*2 - _currentAngle;
                }
                
                self.rotation += chaju;
                NSLog(@"chaju :%f   current :%f  angle :%f",chaju,_currentAngle,angle);
                sender.view.transform = CGAffineTransformRotate(sender.view.transform, chaju);
            }
            
            _currentAngle = angle;
            
            float juli =  [self distanceBetweenPoints:p2 andPoint:p1];
            if (_currentScale != 10000) {
                float scale = juli/_currentScale;
                self.scale = self.scale*scale;
                 sender.view.transform = CGAffineTransformScale(sender.view.transform, scale, scale);
            }
            
            _currentScale = juli;
           
            
        }else{
            _currentAngle = 10000;
            _currentScale = 10000;
            p1 = [sender locationOfTouch:0 inView:self.superview];
        }
        
        
    }else if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint pointsuper = [sender locationInView:self.superview.superview];
        _currentAngle = 10000;
        _currentScale = 10000;
        if ([self.delegate respondsToSelector:@selector(panEndPoint:andSender:)]) {
            [self.delegate panEndPoint:pointsuper andSender:self];
        }
    }
    
}
//#pragma mark pinch 捏合手势事件
//-(void)pinchView:(UIPinchGestureRecognizer *)sender{
//    //scale 缩放比例
//    //    sender.view.transform = CGAffineTransformMake(sender.scale, 0, 0, sender.scale, 0, 0);
//    //每次缩放以原来位置为标准
//    //    sender.view.transform = CGAffineTransformMakeScale(sender.scale, sender.scale);
//    
//    //每次缩放以上一次为标准
//    self.scale = self.scale*sender.scale;
//    sender.view.transform = CGAffineTransformScale(sender.view.transform, sender.scale, sender.scale);
//    //重新设置缩放比例 1是正常缩放.小于1时是缩小(无论何种操作都是缩小),大于1时是放大(无论何种操作都是放大)
//    sender.scale = 1;
//    
//}
//
//-(void)rotationView:(UIRotationGestureRecognizer *)sender{
//    //    sender.view.transform = CGAffineTransformMake(cos(M_PI_4), sin(M_PI_4), -sin(M_PI_4), cos(M_PI_4), 0, 0);
//    //捏合手势两种改变方式
//    //以原来的位置为标准
////        sender.view.transform = CGAffineTransformMakeRotation(sender.rotation);//rotation 是旋转角度
//    NSLog(@"rotation :%f",sender.rotation);
//    self.rotation += sender.rotation;
//    
//    //两个参数,以上位置为标准
//    sender.view.transform = CGAffineTransformRotate(sender.view.transform, sender.rotation);
//    //消除增量
//    sender.rotation = 0.0;
//    
//}



- (float)angleBetweenPoints:(CGPoint)first andPoint:(CGPoint)second{
    float height = second.y - first.y;
    float width = first.x - second.x;
    float rads = atan(height/width);
    
    // 右上
    if (width>=0 && height>=0) {
        rads = M_PI*2 - rads;
    }
    //左上
    else if(width<0 && height>=0){
        rads = M_PI + fabsf(rads);
    }
    //右下
    else if(width>=0 && height<0){
        rads = fabsf(rads);
    }
    //左下
    else if(width<0 && height<0){
        rads = M_PI - rads;
    }
    
//    NSLog(@"rads :%f",rads);
    
    return rads;
//    return degreesToRadian(rads);
}

- (CGFloat)distanceBetweenPoints:(CGPoint)first andPoint:(CGPoint)second{
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
}


@end
