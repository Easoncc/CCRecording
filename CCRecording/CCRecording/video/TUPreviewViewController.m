//
//  playViewController.m
//  videoTest
//
//  Created by chenchao on 2016/12/2.
//  Copyright © 2016年 chenchao. All rights reserved.
//

#import "TUPreviewViewController.h"
#import "TUVideoEditViewController.h"
#import "TUVideoUpView.h"
#import "TUVideoPreviewDownView.h"
#import "TUEditdownView.h"
#import "TUVideoManager.h"
#import "AVAsset+help.h"
#import "TUMBProgressHUDManager.h"
#import "UIColor+HexString.h"

@interface TUPreviewViewController ()<TUVideoPreviewDownViewDelegate,SCPlayerDelegate,TUVideoEditViewControllerDelegate>

@property (strong, nonatomic) SCPlayer *player;
@property (nonatomic ,strong) SCVideoPlayerView *playerView;

@property (nonatomic ,strong) TUVideoUpView *upview;
@property (nonatomic ,strong) TUVideoPreviewDownView *downView;
@property (nonatomic ,strong) TUEditdownView *editView;

@property (nonatomic ,strong) NSMutableArray *assetArray;

@property (nonatomic ,strong) NSTimer *timer;
@property (nonatomic ,assign) int currentIndex;
@property (nonatomic ,strong) NSMutableArray *editArray;
@property (nonatomic ,assign)BOOL isUploading;
@end

@implementation TUPreviewViewController{
    BOOL _isTapPlaying;
}

- (void)dealloc{
    
}

- (void)didMoveToParentViewController:(UIViewController *)parent{
    if (![parent isEqual:self.parentViewController]) {
        // 开启
        self.player = nil;
        self.playerView = nil;
        [self.timer invalidate];
        self.timer = nil;
        //别忘了删除监听
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"333333"];
    self.navigationController.navigationBarHidden = YES;

    _player = [SCPlayer player];
    _player.delegate = self;
    _player.loopEnabled = NO;
    
    _timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateTimerAction) userInfo:nil repeats:YES];
    //将定时器添加到runloop中
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    [self.view addSubview:self.playerView];
    [self.view addSubview:self.upview];
    [self.view addSubview:self.downView];
    self.downView.session = _recordSession;
    [self.view addSubview:self.editView];
    
    _editArray = [NSMutableArray new];
    _assetArray = [NSMutableArray new];
    for (SCRecordSessionSegment *segment in _recordSession.segments) {
        AVAsset * asset = segment.asset;
        if (asset.playable) {
            [_assetArray addObject:segment.asset];
        }else{
            asset = [AVAsset assetWithURL:segment.url];
             [_assetArray addObject:asset];
        }
    }
//    self.downView.assetArray = _assetArray;
    
    //增加监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appHasGoneInForeground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    

}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    
    // 禁用 iOS7 返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    if (_isUploading) {
        [[TUMBProgressHUDManager sharedInstance] showLoding];
    }
    
    [self startPlayer];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_timer setFireDate:[NSDate distantFuture]];
    [_player pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - view

- (TUEditdownView *)editView{
    if (!_editView) {
        
        TUEditdownView *editView = [[TUEditdownView alloc]initWithFrame:CGRectMake(self.playerView.x,self.playerView.bottom-48, _playerView.width, 48)];
        
        [editView.leftButton addTarget:self action:@selector(editButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [editView.rightButton addTarget:self action:@selector(textButtonClick) forControlEvents:UIControlEventTouchUpInside];
        
        _editView = editView;
        
    }
    return _editView;
}

- (TUVideoPreviewDownView *)downView{
    if (!_downView) {
        
        TUVideoPreviewDownView *view = [TUVideoPreviewDownView new];
        view.delegate = self;
        _downView  = view;
        
    }
    return _downView;
}

- (TUVideoUpView *)upview{
    
    if (!_upview) {
        
        TUVideoUpView *view = [TUVideoUpView new];
        
        view.havePermitButton = YES;
        
        [view.leftButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
        [view.leftButton setImage:[UIImage imageNamed:@"video_back"] forState:UIControlStateNormal];
        
        [view.rightButton addTarget:self action:@selector(okClick) forControlEvents:UIControlEventTouchUpInside];
        [view.rightButton setTitle:@"发布" forState:UIControlStateNormal];
        
        [view.powerButton addTarget:self action:@selector(changepowerPermit) forControlEvents:UIControlEventTouchUpInside];
        
        view.saveButton.hidden = NO;
        [view.saveButton addTarget:self action:@selector(saveClick) forControlEvents:UIControlEventTouchUpInside];
//        [view.saveButton setTitle:@"存到本地" forState:UIControlStateNormal];
        
        [view.saveButton setImage:[UIImage imageNamed:@"save_location_de"] forState:UIControlStateNormal];
        [view.saveButton setImage:[UIImage imageNamed:@"save_location_high"] forState:UIControlStateHighlighted];
        
        view.tabView.hidden = YES;
        
        _upview = view;
        
    }
    
    return _upview;
}

- (SCVideoPlayerView *)playerView{
    if (!_playerView) {
        
        SCVideoPlayerView *playerView = [[SCVideoPlayerView alloc] initWithPlayer:_player];
        playerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        playerView.layer.cornerRadius = 6;
        playerView.layer.shadowColor = [UIColor blackColor].CGColor;//shadowColor阴影颜色
        playerView.layer.shadowOffset = CGSizeMake(3,3);//shadowOffset阴影偏移,x向右偏移4，y向下偏移4，默认(0, -3),这个跟shadowRadius配合使用
        playerView.layer.shadowOpacity = 0.8;//阴影透明度，默认0
        playerView.layer.shadowRadius = 3;//阴影半径，默认3
        UITapGestureRecognizer *tap = [UITapGestureRecognizer new];
        [tap addTarget:self action:@selector(tapPlayView)];
        [playerView addGestureRecognizer:tap];
        
        float y = 44;
        float height = KDeviceHeight - 44 - 80;
        float width = height*KDeviceWidth/KDeviceHeight;
        float x = (KDeviceWidth-width)/2.0;
        
        playerView.frame = CGRectMake(x, y, width, height);
        
        _playerView = playerView;
    }
    return _playerView;
}

#pragma mark - commen

- (void)startPlayer{
    
    [_player setItemByAsset:_assetArray[_currentIndex]];
    [_player play];
    
    [_timer setFireDate:[NSDate distantPast]];
}

#pragma mark - action

- (void)appHasGoneInForeground:(NSNotification *)notification{
    [[TUVideoManager sharedInstance] cancelExport];
    [[TUVideoManager sharedInstance] cancelUploadVideo];
}

- (void)tapPlayView{
    TUVideoEditViewController *editViewcontroller = [TUVideoEditViewController new];
    editViewcontroller.segment = _recordSession.segments[_currentIndex];
    editViewcontroller.delegate = self;
    [self.navigationController pushViewController:editViewcontroller animated:YES];
}

- (void)textButtonClick{
    TUVideoEditViewController *editViewcontroller = [TUVideoEditViewController new];
    editViewcontroller.segment = _recordSession.segments[_currentIndex];
    editViewcontroller.editStatus = videoEditTypeText;
    editViewcontroller.delegate = self;
    [self.navigationController pushViewController:editViewcontroller animated:YES];
}

- (void)editButtonClick{
    TUVideoEditViewController *editViewcontroller = [TUVideoEditViewController new];
    editViewcontroller.segment = _recordSession.segments[_currentIndex];
    editViewcontroller.editStatus = videoEditTypePicture;
    editViewcontroller.delegate = self;
    [self.navigationController pushViewController:editViewcontroller animated:YES];
}

- (void)updateTimerAction{
    
    if (!_player.isPlaying) {
        
        _currentIndex += 1;
        if (_currentIndex >= _recordSession.segments.count) {
            _currentIndex = 0;
        }
        
        [_player setItemByAsset:_assetArray[_currentIndex]];
        [_player play];
        
        [_downView scrollToindex:_currentIndex];
        
    }
    
}

- (void)backClick{
    [self autodelloc];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)autodelloc{
    [self.timer invalidate];
    self.timer = nil;
    self.recordSession = nil;
    self.player.delegate = nil;
    self.player = nil;
    self.playerView = nil;
    
    self.editArray = nil;
    self.assetArray = nil;
}

- (void)okClick{
    AVAsset *asset = [AVAsset mergeAllAvasset:_assetArray];
    TUVideoManager *videoManager = [TUVideoManager sharedInstance];
    videoManager.frameRate = 30;
    _isUploading = YES;
    [[TUMBProgressHUDManager sharedInstance] showLoding];
    CCWeakObj(self)
    [videoManager saveVideoWithAsset:asset andFilter:nil andURL:_recordSession.outputUrl complete:^(BOOL result) {
    
        CCStrongObj(self)
        if (result) {
            if ([self.delegate respondsToSelector:@selector(previewReleaseSuccess)]) {
                [self.delegate previewReleaseSuccess];
            }
            self.isUploading = NO;
            [self autodelloc];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }else{
            [[TUMBProgressHUDManager sharedInstance] showHUD:@"合成失败~"];
        }
        
    }];
    
}

- (void)saveClick{
    [[TUMBProgressHUDManager sharedInstance] showLoding];
    AVAsset *asset = [AVAsset mergeAllAvasset:_assetArray];
     [[TUVideoManager sharedInstance] mergeAndsaveTolibraryWithAsset:asset andfilter:nil url:_recordSession.outputUrl complete:^(NSError *error) {
         if (error) {
             [[TUMBProgressHUDManager sharedInstance] showHUD:@"保存失败~"];
         }else{
             [[TUMBProgressHUDManager sharedInstance] showHUD:@"保存成功~"];
         }
     }];
}

#pragma mark - previewDelegate

- (void)pickoneVideo:(int)index{
    _isTapPlaying = YES;
    _player.loopEnabled = YES;
    _currentIndex = index;
    [_player setItemByAsset:_assetArray[index]];
    [_player play];
}

- (void)pickEnd{
    _isTapPlaying = NO;
    _player.loopEnabled = NO;
}

#pragma mark - playDelegate

- (void)player:(SCPlayer *__nonnull)player didPlay:(CMTime)currentTime loopsCount:(NSInteger)loopsCount{
    
}

#pragma mark - editViewDelegate

- (void)videoAssetisChange{
    [_editArray addObject:[NSNumber numberWithInt:_currentIndex]];
    AVAsset *asset = [AVAsset assetWithURL:_recordSession.segments[_currentIndex].url];
    [_assetArray replaceObjectAtIndex:_currentIndex withObject:asset];
    [self.downView resetImageView:_currentIndex andImage:[AVAsset thumbnail:asset]];
}

@end
