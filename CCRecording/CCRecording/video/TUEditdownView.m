//
//  TUEditdownView.m
//  tataufo
//
//  Created by chenchao on 2016/12/12.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUEditdownView.h"

static const int kheight = 48;

@interface TUEditdownView()

@property (nonatomic ,strong ,readwrite) UIButton *leftButton;
@property (nonatomic ,strong ,readwrite) UIButton *rightButton;

@end

@implementation TUEditdownView


- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, kheight);
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.leftButton];
        [self addSubview:self.rightButton];
    }
    return self;
}

- (UIButton *)leftButton{
    
    if (!_leftButton) {
        
        UIButton *button = [UIButton new];
        button.frame = CGRectMake(0, 0, self.width/2, kheight);
        [button setImage:[UIImage imageNamed:@"video_pen"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"video_pen_high"] forState:UIControlStateHighlighted];
        _leftButton = button;
        
    }
    return _leftButton;
    
}

- (UIButton *)rightButton{
    
    if (!_rightButton) {
        
        UIButton *button = [UIButton new];
        button.frame = CGRectMake(self.width/2, 0, self.width/2, kheight);
        [button setImage:[UIImage imageNamed:@"video_text_default"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"video_text_high"] forState:UIControlStateHighlighted];
        _rightButton = button;
        
    }
    return _rightButton;
    
}



@end
