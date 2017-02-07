//
//  TUVideoUpView.m
//  tataufo
//
//  Created by chenchao on 2016/12/8.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUVideoUpView.h"
#import "TUVideoManager.h"
static const int kheight = 44;
@interface TUVideoUpView()
{
    NSInteger _powerPermit;
    BOOL _havePermitButton;
}

@property (nonatomic ,strong ,readwrite) UIButton *leftButton;
@property (nonatomic ,strong ,readwrite) UIButton *rightButton;
@property (nonatomic ,strong ,readwrite) UIButton *saveButton;
@property (nonatomic ,strong ,readwrite) UIButton *powerButton;
@property (nonatomic ,strong ,readwrite) UIView *tabView;

@end

@implementation TUVideoUpView{
    NSMutableArray *_layerArray;
}

- (void)setPowerPermit
{
    if(_powerPermit==3){
        _powerPermit = 1;
    }else{
        _powerPermit++;
    }
    [self setPowerPermitType:_powerPermit];
}

- (void)setPowerPermitType:(NSInteger)powerPermit
{
    _powerPermit = powerPermit;
    [[TUVideoManager sharedInstance] setPowerPermit:powerPermit];
    UILabel * label = (UILabel*)[self.powerButton viewWithTag:2001];
    if (label) {
        switch (_powerPermit) {
            case 1:{
                label.text = @"公开";
                break;
            }
            case 2:{
                label.text = @"仅好友可见";
                break;
            }
            case 3:{
                label.text = @"私密";
                break;
            }
            default:
                break;
        }
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
//    [self.leftButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.bottom.mas_equalTo(0);
//        make.left.mas_equalTo(10);
//        make.width.mas_greaterThanOrEqualTo(kheight);
//    }];
//    
//    [self.rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.bottom.mas_equalTo(0);
//        make.right.mas_equalTo(-10);
//        make.width.mas_greaterThanOrEqualTo(kheight);
//    }];
//    
//    if (_havePermitButton) {
//        UIImageView * imageView = (UIImageView*)[self.powerButton viewWithTag:2002];
//        if (imageView) {
//            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.centerY.mas_equalTo(self.powerButton.mas_centerY);
//                make.right.equalTo(self.powerButton.mas_right).offset(-6);;
//                make.width.mas_equalTo(@(14));
//                make.height.mas_equalTo(@(11));
//            }];
//        }
//        
//        UILabel * label = (UILabel*)[self.powerButton viewWithTag:2001];
//        if (label) {
//            [label mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.top.bottom.mas_equalTo(0);
//                make.centerY.mas_equalTo(self.powerButton.mas_centerY);
//                make.right.equalTo(imageView?imageView.mas_left:self.powerButton.mas_right).offset(-6);
//                make.left.equalTo(self.powerButton.mas_left).offset(6);
//            }];
//        }
//        
//        [self.powerButton mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.height.equalTo(@(20));
//            make.centerY.mas_equalTo(self.rightButton.mas_centerY);
//            make.right.equalTo(self.rightButton.mas_left).offset(-10);
//        }];
//        
//        [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.bottom.mas_equalTo(0);
//            make.right.equalTo(self.powerButton.mas_left).offset(-10);
//            make.width.mas_greaterThanOrEqualTo(kheight);
//        }];
//    }else{
//        [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.bottom.mas_equalTo(0);
//            make.right.equalTo(self.rightButton.mas_left).offset(-10);
//            make.width.mas_greaterThanOrEqualTo(kheight);
//        }];
//    }
    
    
}

- (void)setHavePermitButton:(BOOL)havePermitButton
{
    if (_havePermitButton!=havePermitButton) {
        _havePermitButton = havePermitButton;
        if (_havePermitButton&&!_powerButton) {
            [self addSubview:self.powerButton];
            [self setPowerPermitType:1];
        }
        [self setNeedsLayout];
    }
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, KDeviceWidth, kheight);
        self.backgroundColor = [UIColor clearColor];
        _havePermitButton = NO;
        _layerArray = [NSMutableArray new];
        
        [self addSubview:self.leftButton];
        [self addSubview:self.rightButton];
        [self addSubview:self.saveButton];
        [self addSubview:self.tabView];
        [[TUVideoManager sharedInstance] setPowerPermit:1];
        if (_havePermitButton) {
            [self addSubview:self.powerButton];
            [self setPowerPermitType:1];
        }
    }
    return self;
}

- (UIButton *)leftButton{
    
    if (!_leftButton) {
        
        UIButton *button = [UIButton new];
//        button.frame = CGRectMake(10, 0, kheight, kheight);
        _leftButton = button;
        
    }
    return _leftButton;
    
}

- (UIButton *)powerButton{
    if (!_powerButton) {
        UIButton * button = [UIButton new];
        for (UIView * view in button.subviews) {
            [view removeFromSuperview];
        }
        UILabel * titleLabel = [[UILabel alloc] init];
        titleLabel.tag = 2001;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:13.0];
        
        UIImageView * imageView = [[UIImageView alloc] init];
        imageView.tag = 2001;
        imageView.image = [UIImage imageNamed:@"权限下拉箭头"];
        
        [button addSubview:titleLabel];
        [button addSubview:imageView];
        
        button.layer.borderWidth=0.5;
        button.layer.borderColor=[UIColor whiteColor].CGColor;
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = YES;

        _powerButton = button;
    }
    return _powerButton;
}

- (UIButton *)rightButton{
    
    if (!_rightButton) {
        
        UIButton *button = [UIButton new];
//        button.frame = CGRectMake(self.width - 10 - kheight, 0, kheight, kheight);
        _rightButton = button;
        
    }
    return _rightButton;
    
}

- (UIButton *)saveButton{
    if (!_saveButton) {
        
        UIButton *button = [UIButton new];
        button.hidden = YES;
//        button.frame = CGRectMake(self.width - 10 - kheight - 5 - kheight*2 , 0, kheight*2, kheight);
        _saveButton = button;
        
    }
    return _saveButton;
}

- (UIView *)tabView{
    if (!_tabView) {
        
        UIView *view = [UIView new];
        view.frame = CGRectMake(KDeviceWidth/2-80, 0, 160, kheight);
        view.backgroundColor = [UIColor clearColor];
        
        UIButton *leftButton = [UIButton new];
        leftButton.tag = 2;
        leftButton.frame = CGRectMake(0, 0, 80, 44);
        [leftButton setTitle:@"闪拍" forState:UIControlStateNormal];
        [leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [leftButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.75] forState:UIControlStateNormal];
        leftButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        leftButton.selected = YES;
        [leftButton addTarget:self action:@selector(tabButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:leftButton];
        
        UIButton *rightButton = [UIButton new];
        rightButton.tag = 1;
        rightButton.frame = CGRectMake(80, 0, 80, 44);
        [rightButton setTitle:@"视频" forState:UIControlStateNormal];
        [rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [rightButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.75] forState:UIControlStateNormal];
        rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [rightButton addTarget:self action:@selector(tabButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:rightButton];
        
        UIView *lineView = [UIView new];
        lineView.tag = 3;
        lineView.frame = CGRectMake(15, 43, 50, 2);
        lineView.backgroundColor = [UIColor whiteColor];
        [view addSubview:lineView];
        
        if ([self.delegate respondsToSelector:@selector(tabButtonSelected:)]) {
            [self.delegate tabButtonSelected:videoTypeVideo];
        }
        
        _tabView = view;
        
    }
    return _tabView;
}

- (void)tabButtonClick:(UIButton *)button{
    
    if (button.selected) {
        
    }else{
        
        button.selected = YES;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        
        UIButton *otherButton = [_tabView viewWithTag:button.tag==1?2:1];
        otherButton.selected = NO;
        otherButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        
        UIView *lineView = [_tabView viewWithTag:3];
        [UIView animateWithDuration:0.2 animations:^{
            lineView.centerX = button.centerX;
        }];
        
        if ([self.delegate respondsToSelector:@selector(tabButtonSelected:)]) {
            [self.delegate tabButtonSelected:(int)button.tag-1];
        }
        
    }
    
}

- (void)setSession:(SCRecordSession *)session{
    _session = session;
    float left = 0;
    float allTime = 0;
    int count = (int)session.segments.count;
    
    if (count == _layerArray.count) {
        CALayer *layer = [CALayer new];
        [_layerArray addObject:layer];
    }
    
    if (count > 0) {
        CALayer *layerleft = _layerArray[count-1];
        left = layerleft.frame.size.width + layerleft.frame.origin.x + 2;
        allTime =  CMTimeGetSeconds(_session.duration) - CMTimeGetSeconds(_session.currentSegmentDuration);
        
        for (CALayer *layer in _layerArray) {
            layer.backgroundColor = [UIColor whiteColor].CGColor;
        }
    }
    
    CALayer *layer = _layerArray[count];
    [self.layer addSublayer:layer];
    layer.backgroundColor = [UIColor whiteColor].CGColor;
    float time = CMTimeGetSeconds(_session.currentSegmentDuration);
    float width = (float)(self.width-left)*time/(_maxtime-allTime);
    layer.frame = CGRectMake(left, 0, width, 4);
    
}

- (void)redLastLine:(int)index{
    CALayer *layer = _layerArray[index];
    layer.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1].CGColor;
}

- (void)deleteLastLine{
    CALayer *layer = _layerArray.lastObject;
    [layer removeFromSuperlayer];
    [_layerArray removeLastObject];
    layer = nil;
}

- (void)resetLine{
    for (CALayer *layer in _layerArray) {
        [layer removeFromSuperlayer];
    }
    [_layerArray removeAllObjects];
}

- (void)swipeButton:(int)index{
    
    UIButton *button = [self.tabView viewWithTag:index];
    
    [self tabButtonClick:button];
    
}


@end

