//
//  TUVideoEditViewController.m
//  tataufo
//
//  Created by chenchao on 2016/12/5.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUVideoEditViewController.h"
#import "TUWaterView.h"
#import "SCRecordSession+TUHelp.h"
#import "TUVideoUpView.h"
#import "TUEditdownView.h"
#import "TUColorView.h"
#import "TUDrawingView.h"
#import "TUVideoTextImageView.h"
#import "TUVideoManager.h"
#import "AVAsset+help.h"
#import "NSString+Size.h"
#import "TUMBProgressHUDManager.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "UIColor+HexString.h"

@interface TUVideoEditViewController ()<SCAssetExportSessionDelegate,TUColorViewDelegate,TUVideoTextImageViewDelegate>

@property (nonatomic ,strong) SCVideoPlayerView *videoPlayerView;
@property (nonatomic ,strong) TUVideoUpView *upview;
@property (nonatomic ,strong) TUEditdownView *editView;
@property (nonatomic ,strong) TUColorView *colorView;

@property (nonatomic ,strong) SCFilter *filter;
@property (nonatomic ,strong) SCPlayer *player;

@property (nonatomic ,strong) SCAssetExportSession *exportSession;
@property (nonatomic ,strong) UILabel *titleLabel;
@property (nonatomic ,strong) TUDrawingView *drawView;
@property (nonatomic ,strong) UIView *textBackGroundView;
@property (nonatomic ,strong) UITextView *textView;
@property (nonatomic ,strong) NSMutableArray *textViewArray;
@end

@implementation TUVideoEditViewController{
    NSMutableArray *_thumbnails;
    NSInteger _currentSelected;
    TUVideoTextImageView *_currentTextImageView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)didMoveToParentViewController:(UIViewController *)parent{
    if (![parent isEqual:self.parentViewController]) {
        //别忘了删除监听
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (_isFlash) {
        // 禁用 iOS7 返回手势
        if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        }
    }
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    [self playAsset:0];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"333333"];
    self.navigationController.navigationBarHidden = YES;
    _textViewArray = [NSMutableArray new];
    _player = [SCPlayer player];
    _player.loopEnabled = YES;

    [self.view addSubview:self.videoPlayerView];
    [self.view addSubview:self.upview];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.editView];
    [self.view addSubview:self.drawView];
    [self.view addSubview:self.textBackGroundView];
    [self.view addSubview:self.colorView];
    [self.view addSubview:self.textView];
    
    self.textView.hidden = YES;
    self.colorView.hidden = YES;
    self.drawView.userInteractionEnabled = NO;
    
    switch (_editStatus) {
        case videoEditTypeText:
            [self textButtonClick];
            break;
        case videoEditTypePicture:
            [self editButtonClick];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appHasGoneInForeground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_player pause];
}


#pragma mark - view

- (UIView *)textBackGroundView{
    if (!_textBackGroundView) {
        UIView *view = [[UIView alloc] initWithFrame:self.videoPlayerView.frame];
        view.backgroundColor = [UIColor clearColor];
        view.layer.masksToBounds = YES;
        _textBackGroundView = view;
        
    }
    return _textBackGroundView;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        
        UILabel *label = [UILabel new];
        label.frame = CGRectMake(0, 0, KDeviceWidth, 44);
        label.font = [UIFont systemFontOfSize:17.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        
        _titleLabel = label;
        
    }
    return _titleLabel;
}

- (UITextView *)textView{
    if (!_textView) {
     
        UITextView *textview = [UITextView new];
        textview.frame = CGRectMake(0, 0, self.videoPlayerView.width, 200);
        textview.center = self.videoPlayerView.center;
        textview.font = [UIFont systemFontOfSize:40.0];
        textview.textAlignment = NSTextAlignmentCenter;
        textview.backgroundColor = [UIColor clearColor];
        textview.textColor = [UIColor whiteColor];
        
        TUColorView *colorview = [TUColorView new];
        colorview.delegate = self;
        
        textview.inputAccessoryView = colorview;
        
        _textView = textview;
        
    }
    return _textView;
}

- (TUDrawingView *)drawView{
    if (!_drawView) {
     
        TUDrawingView *drawView = [[TUDrawingView alloc] initWithFrame:self.videoPlayerView.frame];
        drawView.lineColor = [UIColor whiteColor];
        drawView.lineWidth = 5;
        drawView.layer.masksToBounds = YES;
        drawView.backgroundColor = [UIColor clearColor];
        
        _drawView = drawView;
    }
    return _drawView;
}

- (TUColorView *)colorView{
    if (!_colorView) {
        
        TUColorView *colorView = [TUColorView new];
        colorView.delegate = self;
        _colorView = colorView;
        
    }
    return _colorView;
}

- (TUEditdownView *)editView{
    if (!_editView) {
        
        TUEditdownView *editView = [[TUEditdownView alloc]initWithFrame:CGRectMake(0,KDeviceHeight-48, KDeviceWidth, 48)];
        
        [editView.leftButton addTarget:self action:@selector(editButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [editView.rightButton addTarget:self action:@selector(textButtonClick) forControlEvents:UIControlEventTouchUpInside];
        
        _editView = editView;
        
    }
    return _editView;
}

- (TUVideoUpView *)upview{
    
    if (!_upview) {
        
        TUVideoUpView *view = [TUVideoUpView new];
        
        [view.leftButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
        [view.leftButton setImage:[UIImage imageNamed:@"video_back"] forState:UIControlStateNormal];
        
        [view.rightButton addTarget:self action:@selector(okClick) forControlEvents:UIControlEventTouchUpInside];
        if (_isFlash) {
            [view.rightButton setTitle:@"发布" forState:UIControlStateNormal];
            view.saveButton.hidden = NO;
            view.havePermitButton = YES;
            view.powerButton.hidden = NO;
            [view.powerButton addTarget:self action:@selector(changepowerPermit) forControlEvents:UIControlEventTouchUpInside];
            [view.saveButton addTarget:self action:@selector(saveClick) forControlEvents:UIControlEventTouchUpInside];
            [view.saveButton setImage:[UIImage imageNamed:@"save_location_de"] forState:UIControlStateNormal];
            [view.saveButton setImage:[UIImage imageNamed:@"save_location_high"] forState:UIControlStateHighlighted];
        }else{
            [view.rightButton setTitle:@"合并" forState:UIControlStateNormal];
        }
        
        view.tabView.hidden = YES;
        
        _upview = view;
        
    }
    
    return _upview;
}

- (SCVideoPlayerView *)videoPlayerView{
    if (!_videoPlayerView) {
        
        SCVideoPlayerView *playerView = [[SCVideoPlayerView alloc] initWithPlayer:_player];
        playerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        playerView.layer.cornerRadius = 6;
        playerView.layer.shadowColor = [UIColor blackColor].CGColor;//shadowColor阴影颜色
        playerView.layer.shadowOffset = CGSizeMake(3,3);//shadowOffset阴影偏移,x向右偏移4，y向下偏移4，默认(0, -3),这个跟shadowRadius配合使用
        playerView.layer.shadowOpacity = 0.8;//阴影透明度，默认0
        playerView.layer.shadowRadius = 3;//阴影半径，默认3
        
        float y = 44;
        float height = KDeviceHeight - 44 - 48;
        float width = height*KDeviceWidth/KDeviceHeight;
        float x = (KDeviceWidth-width)/2.0;
        
        playerView.frame = CGRectMake(x, y, width, height);
        
        _videoPlayerView = playerView;
        
    }
    return _videoPlayerView;
}

#pragma mark - commen

- (void)playAsset:(int)index{
    AVAsset * asset = [AVAsset assetWithURL:_segment.url];
    if (asset.playable) {
        if (!_player) {
            _player = [SCPlayer player];
            _player.loopEnabled = YES;
            
            self.videoPlayerView = nil;
            [self.view insertSubview:self.videoPlayerView belowSubview:self.upview];
        }
        
        [_player setItemByAsset:asset];
        [_player play];
    }else{
        if (index<=3) {
            int blockIndex = index++;
            NSString *text = [NSString stringWithFormat:@"视频正在载入，第%d次",blockIndex];
            [[TUMBProgressHUDManager sharedInstance] showLodingWithText:text];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self playAsset:blockIndex];
            });
        }else{
            [[TUMBProgressHUDManager sharedInstance] showHUD:@"视频加载失败~"];
        }
    }
}

- (UIImage *)addImage:(UIImage *)image1 withImage:(UIImage *)image2 {

    float width = 360*2.0;
    float height = 640*2.0;
    
    if (!_isFlash) {
        UIImage *image = _segment.thumbnail;
        width = image.size.width;
        height = image.size.height;
    }

    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    [image1 drawInRect:CGRectMake(0, 0, width, height)];
    [image2 drawInRect:CGRectMake(0,0, width, height)];
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resultingImage;
}

-(UIImage*)convertViewToImage:(UIView*)v{
    CGSize s = v.bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [v.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(UIImage*)convertViewScreenSizeToImage:(UIView*)v{
    CGSize s = [UIScreen mainScreen].bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了[UIScreen mainScreen].scale
    float scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(s, NO, scale);
    [v.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)editText{
    
    _editStatus = videoEditTypeText;
    self.textView.hidden = NO;
    self.upview.saveButton.hidden = YES;
    self.upview.powerButton.hidden = YES;
    [self.textView becomeFirstResponder];
    
    [self.upview.leftButton setTitle:@"" forState:UIControlStateNormal];
    [self.upview.leftButton setImage:nil forState:UIControlStateNormal];
    [self.upview.rightButton setTitle:@"完成" forState:UIControlStateNormal];
    
    [self.upview.leftButton removeTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [self.upview.rightButton removeTarget:self action:@selector(okClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.upview.rightButton addTarget:self action:@selector(completeEidt) forControlEvents:UIControlEventTouchUpInside];
}

- (UIImage *)getimageFilter{
    
    UIImageView *draw1 = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    draw1.image = [self convertViewToImage:self.drawView];
    
    UIImageView *draw2 = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    draw2.image = [self convertViewToImage:self.textBackGroundView];
    
    UIImage *drawImage = [self convertViewScreenSizeToImage:draw1];
    UIImage *textImage = [self convertViewScreenSizeToImage:draw2];
    
    UIImage *resultImage = [self addImage:drawImage withImage:textImage];
    
    SCFilter *filter = [SCFilter filterWithCIImage:[CIImage imageWithCGImage:resultImage.CGImage]];
    self.filter = filter;
    
    return resultImage;
}

- (void)oktoFlash{
    
    SCFilter *filter = self.filter;
    if ([self.drawView getLineCount] == 0 && _textViewArray.count == 0) {
        filter = nil;
    }
    [[TUMBProgressHUDManager sharedInstance] showLoding];
    [self getimageFilter];
    
    TUVideoManager *manager = [TUVideoManager sharedInstance];
    manager.frameRate = 12;
    AVAsset *asset = [AVAsset mergeFlashAvasset:@[[AVAsset assetWithURL:_segment.url]]];
   CCWeakObj(self)
    [manager saveVideoWithAsset:asset andFilter:self.filter andURL:_segment.url complete:^(BOOL result) {
        CCStrongObj(self)
        if (!result) {
            [[TUMBProgressHUDManager sharedInstance]  showHUD:@"合并失败~"];
            return ;
        }
        if ([self.delegate respondsToSelector:@selector(editReleaseSuccess)]) {
            [self.delegate editReleaseSuccess];
        }
        [self.navigationController popToRootViewControllerAnimated:NO];
        
    }];
}

- (void)oktoVideo{
    
    if ([self.drawView getLineCount] == 0 && _textViewArray.count == 0) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    [[TUMBProgressHUDManager sharedInstance] showLoding];
    [self getimageFilter];

    TUVideoManager *manager = [TUVideoManager sharedInstance];
    manager.frameRate = 30;
    
    CCWeakObj(self)
    AVAsset *asset = [AVAsset mergeAllAvasset:@[[AVAsset assetWithURL:_segment.url]]];
    [manager saveVideoWithAsset:asset andFilter:self.filter andURL:_segment.url complete:^(BOOL result) {
        CCStrongObj(self)
        
        if (!result) {
            [[TUMBProgressHUDManager sharedInstance] showHUD:@"合并失败~"];
            return ;
        }
        
        if (result) {
            
            [[TUMBProgressHUDManager sharedInstance] showHUD:@"合并成功~"];
            if ([self.delegate respondsToSelector:@selector(videoAssetisChange)]) {
                [self.delegate videoAssetisChange];
            }
            [self.navigationController popViewControllerAnimated:YES];
        }else{
            [[TUMBProgressHUDManager sharedInstance] showHUD:@"合并失败~"];
        }

    }];
}



#pragma mark - action

- (void)appHasGoneInForeground:(NSNotification *)notification{
    [[TUVideoManager sharedInstance] cancelExport];
    [[TUVideoManager sharedInstance] cancelUploadVideo];
}

- (void)saveClick{
    
    [[TUMBProgressHUDManager sharedInstance] showLoding];
    AVAsset *asset = [AVAsset mergeFlashAvasset:@[[AVAsset assetWithURL:_segment.url]]];
    [self getimageFilter];
    [[TUVideoManager sharedInstance] mergeAndsaveTolibraryWithAsset:asset andfilter:self.filter url:_segment.url complete:^(NSError *error) {
        if (error) {
            [[TUMBProgressHUDManager sharedInstance] showHUD:@"保存失败~"];
        }else{
            [[TUMBProgressHUDManager sharedInstance] showHUD:@"保存成功~"];
        }
    }];
}

//添加文字
- (void)textButtonClick{
    
    _currentTextImageView = nil;
    self.textView.text = @"";
    [self editText];
}
//涂鸦
- (void)editButtonClick{
    
    _editStatus = videoEditTypePicture;
    self.editView.hidden = YES;
    self.colorView.hidden = NO;
    self.upview.saveButton.hidden = YES;
    self.upview.powerButton.hidden = YES;
    
    self.textBackGroundView.userInteractionEnabled = NO;
    self.drawView.userInteractionEnabled = YES;
    
    [self.upview.leftButton setTitle:@"撤销" forState:UIControlStateNormal];
    [self.upview.leftButton setImage:nil forState:UIControlStateNormal];
    [self.upview.rightButton setTitle:@"完成" forState:UIControlStateNormal];
    
    [self.upview.leftButton removeTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [self.upview.rightButton removeTarget:self action:@selector(okClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.upview.leftButton addTarget:self action:@selector(removeLine) forControlEvents:UIControlEventTouchUpInside];
    [self.upview.rightButton addTarget:self action:@selector(completeEidt) forControlEvents:UIControlEventTouchUpInside];
    
}
//返回
- (void)backClick{
    if (_isFlash) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
// 保存
- (void)okClick{
    
    if (_isFlash) {
        [self oktoFlash];
    }else{
        [self oktoVideo];
    }

}
//撤销
- (void)removeLine{
    [self.drawView removeLastLine];
}
//完成
- (void)completeEidt{
    
    switch (_editStatus) {
        case videoEditTypeText:{
            [self.textView resignFirstResponder];
            self.textView.hidden = YES;
            NSString *trimmedString = [self.textView.text stringByTrimmingCharactersInSet:
                                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            self.textView.text = trimmedString;
            if (self.textView.text.length == 0) {
                break;
            }
            
            CGSize size = [self.textView.text getTextSizeWithMaxWidth:self.textView.width*200/50.0 MaxHeight:MAXFLOAT andFont:[UIFont systemFontOfSize:200.0]];
            UILabel *label = [UILabel new];
            label.font = [UIFont systemFontOfSize:200.0];
            label.textColor = self.textView.textColor;
            label.text = self.textView.text;
            label.numberOfLines = 0;
            label.textAlignment = NSTextAlignmentCenter;
            
            if (size.width<100*4) {
                size.width = 100*4;
            }
            
            if (size.height <100*4) {
                size.height = 100*4;
            }
            
            label.size = size;
            label.center = self.textView.center;
           
            size = [self.textView.text getTextSizeWithMaxWidth:self.textView.width MaxHeight:MAXFLOAT andFont:[UIFont systemFontOfSize:50.0]];
            
            if (size.width<100) {
                size.width = 100;
            }
            
            if (size.height <100) {
                size.height = 100;
            }
            if (_currentTextImageView) {
                
                CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);
                _currentTextImageView.transform = transform;
                _currentTextImageView.size = size;
                _currentTextImageView.image = [self convertViewToImage:label];
                
                _currentTextImageView.transform = CGAffineTransformTranslate(_currentTextImageView.transform,_currentTextImageView.offsetPoint.x, _currentTextImageView.offsetPoint.y);
                _currentTextImageView.transform = CGAffineTransformScale(_currentTextImageView.transform, _currentTextImageView.scale, _currentTextImageView.scale);
                _currentTextImageView.transform = CGAffineTransformRotate(_currentTextImageView.transform, _currentTextImageView.rotation);
                _currentTextImageView.hidden = NO;
                _currentTextImageView.text = self.textView.text;
                
            }else{
                
                TUVideoTextImageView *imageView = [TUVideoTextImageView new];
                imageView.image = [self convertViewToImage:label];
                imageView.tag = _textViewArray.count+200;
                imageView.userInteractionEnabled = YES;
                imageView.delegate = self;
                imageView.size = size;
                imageView.center = CGPointMake(self.view.centerX-self.videoPlayerView.left, self.view.centerY-self.videoPlayerView.top);
                imageView.text = self.textView.text;
                [self.textBackGroundView addSubview:imageView];
                [_textViewArray addObject:imageView];
                
            }
            
            label = nil;
            

            [[TUMBProgressHUDManager sharedInstance] showHUD:@"双指可旋转文字~"];

            
        }
            
            break;
        case videoEditTypePicture:{
            self.editView.hidden = NO;
            self.colorView.hidden = YES;
    
            self.textBackGroundView.userInteractionEnabled = YES;
            self.drawView.userInteractionEnabled = NO;
        }
            
            break;
            
        default:
            break;
    }
    
    _editStatus = videoEditTypeNo;
    
    [self.upview.leftButton removeTarget:self action:@selector(removeLine) forControlEvents:UIControlEventTouchUpInside];
    [self.upview.leftButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [self.upview.leftButton setImage:[UIImage imageNamed:@"video_back"] forState:UIControlStateNormal];
    [self.upview.leftButton setTitle:@"" forState:UIControlStateNormal];
    
    [self.upview.rightButton removeTarget:self action:@selector(completeEidt) forControlEvents:UIControlEventTouchUpInside];
    [self.upview.rightButton addTarget:self action:@selector(okClick) forControlEvents:UIControlEventTouchUpInside];
    if (_isFlash) {
        self.upview.havePermitButton = YES;
        [self.upview.rightButton setTitle:@"发布" forState:UIControlStateNormal];
        self.upview.saveButton.hidden = NO;
        self.upview.powerButton.hidden = NO;
    }else{
        self.upview.havePermitButton = NO;
        [self.upview.rightButton setTitle:@"合并" forState:UIControlStateNormal];
    }
}

#pragma mark - delegate
- (void)assetExportSessionDidProgress:(SCAssetExportSession *__nonnull)assetExportSession{
    
}

#pragma mark - colorDelegate

- (void)tapColor:(UIColor *)color{
    
    switch (_editStatus) {
        case videoEditTypeText:
            _textView.textColor = color;
            break;
        case videoEditTypePicture:
            _drawView.lineColor = color;
            break;
            
        default:
            break;
    }
}

#pragma mark - textimageDelegate

- (void)panBeginPointdSender:(id)sender{
    self.titleLabel.text = @"移出屏幕以删除文字";
    self.upview.leftButton.hidden = YES;
    self.upview.rightButton.hidden = YES;
    self.upview.saveButton.hidden = YES;
    self.upview.powerButton.hidden = YES;
    self.editView.hidden = YES;
}

- (void)panMovePoint:(CGPoint)point andSender:(id)sender{
    
    UIColor *backGroundColor = [UIColor colorWithHexString:@"FF3B30"];
    if (point.x<self.videoPlayerView.x) {
        self.view.backgroundColor = backGroundColor;
        self.titleLabel.text = @"松开以删除文字";
    }else if (point.y<self.videoPlayerView.y) {
        self.view.backgroundColor = backGroundColor;
        self.titleLabel.text = @"松开以删除文字";
    }else if (point.x>self.videoPlayerView.x+self.videoPlayerView.width) {
        self.view.backgroundColor = backGroundColor;
        self.titleLabel.text = @"松开以删除文字";
    }else if (point.y>self.videoPlayerView.y+self.videoPlayerView.height) {
        self.view.backgroundColor = backGroundColor;
        self.titleLabel.text = @"松开以删除文字";
    }else{
        self.view.backgroundColor = [UIColor colorWithHexString:@"333333"];
        self.titleLabel.text = @"移出屏幕以删除文字";
    }
}

- (void)panEndPoint:(CGPoint)point andSender:(id)sender{
    
    self.titleLabel.text = @"";
    self.upview.leftButton.hidden = NO;
    self.upview.saveButton.hidden = NO;
    if (self.upview.havePermitButton) {
        self.upview.powerButton.hidden = NO;
    }
    self.upview.rightButton.hidden = NO;
    self.editView.hidden = NO;
    
    if (point.x<self.videoPlayerView.x) {
        UIImageView *imageView = (UIImageView *)sender;
        [imageView removeFromSuperview];
        [_textViewArray removeObject:sender];
        imageView = nil;
    }else if (point.y<self.videoPlayerView.y) {
        UIImageView *imageView = (UIImageView *)sender;
        [imageView removeFromSuperview];
        [_textViewArray removeObject:sender];
        imageView = nil;
    }else if (point.x>self.videoPlayerView.x+self.videoPlayerView.width) {
        UIImageView *imageView = (UIImageView *)sender;
        [imageView removeFromSuperview];
        [_textViewArray removeObject:sender];
        imageView = nil;
    }else if (point.y>self.videoPlayerView.y+self.videoPlayerView.height) {
        UIImageView *imageView = (UIImageView *)sender;
        [imageView removeFromSuperview];
        [_textViewArray removeObject:sender];
        imageView = nil;
    }
    
    self.view.backgroundColor = [UIColor colorWithHexString:@"333333"];
}

- (void)tapImageToEdit:(id)sender{
    
    TUVideoTextImageView *imageview = (TUVideoTextImageView *)sender;
    _currentTextImageView = imageview;
    _currentTextImageView.hidden = YES;
    self.textView.text = imageview.text;
    
    [self editText];
}

@end
