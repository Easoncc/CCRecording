//
//  TUVideoDowmView.m
//  tataufo
//
//  Created by chenchao on 2016/12/9.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUVideoDowmView.h"

static const int kheight = 44;

@interface TUVideoDowmView()

@property (nonatomic ,strong ,readwrite) UIButton *leftButton;
@property (nonatomic ,strong ,readwrite) UIButton *rightButton;
@property (nonatomic ,strong ,readwrite) UIButton *deleteButton;

@end

@implementation TUVideoDowmView

- (instancetype)init{
    self = [super init];
    if (self) {
        
        self.frame = CGRectMake(0, KDeviceHeight-kheight, KDeviceWidth, kheight);
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.leftButton];
        [self addSubview:self.rightButton];
        [self addSubview:self.deleteButton];
        
    }
    return self;
}



- (UIButton *)leftButton{
    
    if (!_leftButton) {
        
        UIButton *button = [UIButton new];
        button.frame = CGRectMake(10, 0, kheight, kheight);
        _leftButton = button;
        
    }
    return _leftButton;
    
}

- (UIButton *)rightButton{
    
    if (!_rightButton) {
        
        UIButton *button = [UIButton new];
        button.frame = CGRectMake(self.width - 10 - kheight, 0, kheight, kheight);
        _rightButton = button;
        
    }
    return _rightButton;
    
}

- (UIButton *)deleteButton{
    
    if (!_deleteButton) {
        
        UIButton *button = [UIButton new];
        button.frame = CGRectMake(self.width/2-kheight/2, 0, kheight, kheight);
        _deleteButton = button;
        
    }
    return _deleteButton;
    
}

@end
