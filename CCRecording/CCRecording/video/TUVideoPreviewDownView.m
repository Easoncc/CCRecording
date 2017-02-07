//
//  TUVideoPreviewDownView.m
//  tataufo
//
//  Created by chenchao on 2016/12/10.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUVideoPreviewDownView.h"
#import "AVAsset+help.h"
static const int kheight = 80;

@interface TUVideoPreviewDownView()<UIScrollViewDelegate>

@property (nonatomic ,strong ,readwrite) UICollectionView *collectionView;
@property (nonatomic ,strong ,readwrite) UIScrollView *scrollView;

@property (nonatomic ,strong) UIImageView *borderView;
@property (nonatomic ,assign) BOOL isDragging;

@property (nonatomic ,assign) int currentIndex;
@end

@implementation TUVideoPreviewDownView

- (instancetype)init{
    self = [super init];
    if (self) {
        
        self.frame = CGRectMake(0, KDeviceHeight-kheight, KDeviceWidth, kheight);
        self.backgroundColor = [UIColor clearColor];

        [self addSubview:self.scrollView];
        [self addSubview:self.borderView];
        _currentIndex = 10000;
    }
    return self;
}

- (UIScrollView *)scrollView{
    if (!_scrollView) {
        
        UIScrollView *scrollview = [UIScrollView new];
        
        scrollview.frame = CGRectMake(0, 10, self.width, self.height-20);
        scrollview.showsHorizontalScrollIndicator = NO;
        scrollview.showsVerticalScrollIndicator = NO;
        scrollview.bounces = NO;
        scrollview.delegate = self;
        
        _scrollView = scrollview;
        
    }
    return _scrollView;
}

- (UIImageView *)borderView{
    if (!_borderView) {
        
        UIImageView *view = [UIImageView new];
        
        view.frame = CGRectMake(KDeviceWidth/2.0 - 30, 10, 60, 60);
        view.backgroundColor = [UIColor clearColor];
        view.contentMode = UIViewContentModeCenter;
        view.layer.cornerRadius = 6;
        view.layer.borderColor = [UIColor whiteColor].CGColor;
        view.layer.borderWidth = 1;
        
        _borderView = view;
    }
    return _borderView;
}

- (void)setSession:(SCRecordSession *)session{
    _session = session;
    
    float left = KDeviceWidth/2.0 - 30;
    float right = left;
    float width = left+right+(_session.segments.count-1)*10+_session.segments.count*60;
    self.scrollView.contentSize = CGSizeMake(width, 60);
    
    for (int i =0; i <_session.segments.count; i++) {
        
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.masksToBounds = YES;
        imageView.image = [[_session.segments objectAtIndex:i] thumbnail];
        imageView.layer.cornerRadius = 6;
        imageView.tag = 100+i;
        imageView.userInteractionEnabled = YES;
        float imageWidth = left+i*60+i*10;
        imageView.frame = CGRectMake(imageWidth, 0, 60, 60);
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPress:)];
        [imageView addGestureRecognizer:tap];
        
        [self.scrollView addSubview:imageView];
        
    }
    
}

- (void)scrollToindex:(int)index{
    if (!_isDragging) {
        [self.scrollView setContentOffset:CGPointMake(index*60+index*10, 0) animated:YES];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;{
    _isDragging = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    _isDragging = NO;
}

- (void)resetImageView:(int)index andImage:(UIImage *)image{
    UIImageView *imageview =  [self.scrollView viewWithTag:100+index];
    [imageview setImage:image];
}

- (void)tapPress:(UITapGestureRecognizer *)press{
    
    int i = (int)press.view.tag - 100;
    
    if (self.currentIndex == i) {
        
        self.currentIndex = 10000;
        
        self.borderView.image = nil;
        
        if ([self.delegate respondsToSelector:@selector(pickEnd)]) {
            [self.delegate pickEnd];
        }
        
    }else{
        
        self.currentIndex = i;
        self.borderView.image = [UIImage imageNamed:@"video_playback"];
        float left = KDeviceWidth/2.0 - 30;
        float imageWidth = left+i*60+i*10;
        [self.scrollView setContentOffset:CGPointMake(imageWidth-left, 0) animated:YES];
        
        if ([self.delegate respondsToSelector:@selector(pickoneVideo:)]) {
            [self.delegate pickoneVideo:i];
        }
    }
}

@end
