//
//  TUWaterView.m
//  tataufo
//
//  Created by chenchao on 2016/12/5.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUWaterView.h"

@interface TUWaterView()

@property (nonatomic ,strong) UIImageView *imageView;

@end

@implementation TUWaterView

- (instancetype)init{
    self = [super init];
    
    if (self) {
        [self addSubview:self.imageView];
        
    }
    
    return self;
}

- (UIImageView *)imageView{
    if (!_imageView) {
        UIImageView *imageView = [UIImageView new];
        _imageView = imageView;
    }
    return _imageView;
}
- (void)setImage:(UIImage *)image{
    self.imageView.image = image;
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.size = image.size;
}

@end
