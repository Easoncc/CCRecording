//
//  oneViewController.m
//  videoTest
//
//  Created by chenchao on 2016/12/2.
//  Copyright © 2016年 chenchao. All rights reserved.
//

#import "TURecorderViewController.h"
#import "SCRecorder.h"
#import "TUPreviewViewController.h"
#import "TUVideoUpView.h"
#import "TUVideoManager.h"
#import "TUVideoDowmView.h"
#import "TUVideoEditViewController.h"
#import "AVAsset+help.h"
#import "TUMBProgressHUDManager.h"

static const float kmaxtime = 16;

@interface TURecorderViewController ()<SCRecorderDelegate,TUVideoUpViewDelegate,SCAssetExportSessionDelegate,TUPreviewViewControllerDelegate,TUVideoEditViewControllerDelegate>

@property (nonatomic ,strong) UIView *previewView;
@property (nonatomic ,strong) UIView *recorderView;
@property (nonatomic ,strong) UILabel *timeRecordedLabel;
@property (nonatomic ,strong) UIButton *stopButton;
@property (nonatomic ,strong) TUVideoUpView *upview;
@property (nonatomic ,strong) TUVideoDowmView *downView;

@property (nonatomic ,strong) SCRecorderToolsView *focusView;
@property (nonatomic ,assign) BOOL isfirstcoming;
@property (nonatomic ,assign) BOOL isRecordering;//录制中
@property (nonatomic ,assign) BOOL isCompleted;//录制完成
@property (nonatomic ,strong) SCRecorder *recorder;

@property (nonatomic ,strong) NSTimer *timer;
@property (nonatomic ,strong) UIImageView *flashImageView;
@property (nonatomic ,strong) SCRecordSession *recordSession;

@property(nonatomic, assign)BOOL isRecord;
@property(nonatomic, assign)BOOL isClickVideo;

@end

@implementation TURecorderViewController{
    videoType _videoType;
    float _maxFrameDuration;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[TUMBProgressHUDManager sharedInstance] stoplodingNoAnimate];
    [_recorder stopRunning];
//    _recorder = nil;

}

- (void)didMoveToParentViewController:(UIViewController *)parent{
    if (![parent isEqual:self.parentViewController]) {
        // 开启
        if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
            self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
        self.navigationController.navigationBarHidden = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[TUMBProgressHUDManager sharedInstance] stoplodingNoAnimate];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }

    if (_isfirstcoming) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }else{
        if (_recorder.session == nil) {
            
            SCRecordSession *session = [SCRecordSession recordSession];
            session.fileType = AVFileTypeQuickTimeMovie;
            
            _recorder.session = session;
        }
        
        [self resetUI];
        [_recorder startRunning];
    }

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [[TUVideoManager sharedInstance] isCanRecorder:^(bool status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!status) {
                [[TUMBProgressHUDManager sharedInstance] showNOCameraHUD];
            }else{
                if (_videoType == videoTypeVideo) {
                    _maxFrameDuration = kmaxtime;
                    [[TUMBProgressHUDManager sharedInstance] showlongtimeHUD:@"长按屏幕，进行录制"];
                }else if (_videoType == videoTypeFlash) {
                    _maxFrameDuration = 1.5;
                    [[TUMBProgressHUDManager sharedInstance] showlongtimeHUD:@"单击屏幕，开始闪拍"];
                    
                }
            }
        });
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    
    _maxFrameDuration = kmaxtime;
    
    _videoType = videoTypeFlash;
    [self.view addSubview:self.previewView];
    [self.view addSubview:self.flashImageView];
    [self.view addSubview:self.stopButton];
    [self.view addSubview:self.upview];
    [self.view addSubview:self.downView];
//    [self.view addSubview:self.timeRecordedLabel];
    self.flashImageView.hidden = YES;
    [self initRecorder];

    [[TUVideoManager sharedInstance] removetmpobjects];
}

#pragma mark - commen

- (void)initRecorder{
    
    _recorder = [SCRecorder recorder];
    
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    
//    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
//    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetForDevice:captureDevice withMaxSize:CGSizeMake(720, 1280)];
    
    if (YES) {
        _recorder.device = AVCaptureDevicePositionBack;
        self.downView.leftButton.hidden = NO;
    }else{
        _recorder.device = AVCaptureDevicePositionFront;
        self.downView.leftButton.hidden = YES;
        self.downView.leftButton.selected = NO;
        _recorder.flashMode = SCFlashModeOff;
    }

    _recorder.initializeSessionLazily = NO;
    _recorder.delegate = self;
    _recorder.autoSetVideoOrientation = NO; //YES causes bad orientation for video from camera roll
    
    _recorder.previewView = self.previewView;
    
}
//判断是否录制完成
- (void)isEndTime{
    CMTime currentTime = kCMTimeZero;
    if (_recorder.session != nil) {
        if (_isCompleted) {
            return;
        }
        currentTime = _recorder.session.duration;

        if (CMTimeGetSeconds(currentTime) >= _maxFrameDuration) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _isCompleted = YES;
                switch (_videoType) {
                    case videoTypeVideo:
                        [self recordVideoEnd];
                        break;
                    case videoTypeFlash:
                        [self recordFlashEnd];
                        break;
                        
                    default:
                        break;
                }
                
            });
        }else{
            
            if (_videoType == videoTypeVideo) {
                self.upview.maxtime = _maxFrameDuration;
                self.upview.session = _recorder.session;
            }
            
        }
    }
}
//视频录制完成
- (void)recordVideoEnd{
    _isCompleted = YES;
    [[TUMBProgressHUDManager sharedInstance] stoploding];
    CCWeakObj(self)
    [_recorder pause:^{
        CCStrongObj(self)
        self.recordSession = self.recorder.session;
        TUPreviewViewController *play = [TUPreviewViewController new];
        play.recordSession = self.recordSession;
        play.delegate = self;
        [self.navigationController pushViewController:play animated:YES];

    }];
}

//闪拍录制完成
- (void)recordFlashEnd{
    CCWeakObj(self)
    [_recorder pause:^{

        CCStrongObj(self)
        self.upview.leftButton.hidden = NO;
        self.upview.tabView.hidden = NO;
        self.upview.rightButton.hidden = NO;
        self.downView.hidden = NO;
        
        self.recordSession = self.recorder.session;
        
        self.flashImageView.hidden = YES;
        [self.timer invalidate];
        self.timer = nil;
        _isRecordering = NO;
        
        [[TUMBProgressHUDManager sharedInstance] showLoding];
        
        NSURL *url = self.recordSession.segments.firstObject.url;
        
        TUVideoManager *videoManager = [TUVideoManager sharedInstance];
        videoManager.frameRate = 12;
        
        [videoManager saveVideoWithAsset:_recordSession.segments.firstObject.asset andFilter:nil andURL:url complete:^(BOOL result) {
            CCWeakObj(url)
            [[TUVideoManager sharedInstance] movieToImage:url block:^(NSArray *array) {
                CCStrongObj(url)
                NSString *path = url.path;
                CCWeakObj(self)
                [[TUVideoManager sharedInstance] mergeFlashQuick:array path:path block:^(BOOL success) {
                    CCStrongObj(self)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[TUMBProgressHUDManager sharedInstance] stoploding];
                        TUVideoEditViewController *play = [TUVideoEditViewController new];
                        play.segment = _recordSession.segments.firstObject;
                        play.isFlash = YES;
                        play.delegate = self;
                        [self.navigationController pushViewController:play animated:YES];
                    });
                }];
            }];
        }];
    }];
}

- (void)updateTimeRecordedLabel {
    CMTime currentTime = kCMTimeZero;
    
    if (_recorder.session != nil) {
        currentTime = _recorder.session.duration;
    }
    
    self.timeRecordedLabel.text = [NSString stringWithFormat:@"%.2f sec", CMTimeGetSeconds(currentTime)];
}

-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

- (void)resetUI{
    if (_recorder.session.segments.count>0) {
        [_recorder.session removeAllSegments];
    }
    _isCompleted = NO;
    self.downView.deleteButton.hidden = YES;
    self.upview.tabView.hidden = NO;
    self.upview.rightButton.hidden = YES;
    self.upview.leftButton.hidden = NO;
    self.upview.hidden = NO;
    self.downView.hidden = NO;
    [self.upview resetLine];
    [self.upview.leftButton setImage:[UIImage imageNamed:@"video_close"] forState:UIControlStateNormal];
}

#pragma mark - view

- (UIImageView *)flashImageView{
    if (!_flashImageView) {
        UIImageView *imageview = [UIImageView new];
        imageview.frame = self.view.frame;
        imageview.image = [UIImage imageNamed:@"mask50"];
        _flashImageView = imageview;
    }
    return  _flashImageView;
}

- (TUVideoDowmView *)downView{
    if (!_downView) {
        
        TUVideoDowmView *view = [TUVideoDowmView new];
        [view.leftButton addTarget:self action:@selector(flashbuttonCick) forControlEvents:UIControlEventTouchUpInside];
        [view.leftButton setImage:[UIImage imageNamed:@"video_light_no"] forState:UIControlStateNormal];//video_light_high
        [view.leftButton setImage:[UIImage imageNamed:@"video_light_high"] forState:UIControlStateSelected];//video_light_high
        
        [view.rightButton addTarget:self action:@selector(frontorbackCick) forControlEvents:UIControlEventTouchUpInside];
        [view.rightButton setImage:[UIImage imageNamed:@"video_ Rotate_default"] forState:UIControlStateNormal];
        [view.rightButton setImage:[UIImage imageNamed:@"video_ Rotate_high"] forState:UIControlStateHighlighted];
        
        [view.deleteButton addTarget:self action:@selector(deleteButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [view.deleteButton setImage:[UIImage imageNamed:@"video_deleteline_default"] forState:UIControlStateNormal];
        [view.deleteButton setImage:[UIImage imageNamed:@"video_deleteline_high"] forState:UIControlStateSelected];
        
        view.deleteButton.hidden = YES;
        _downView = view;
        
    }
    return _downView;
}

- (TUVideoUpView *)upview{
    if (!_upview) {
        
        TUVideoUpView *view = [TUVideoUpView new];
        
        [view.leftButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
        [view.leftButton setImage:[UIImage imageNamed:@"video_close"] forState:UIControlStateNormal];
        
        [view.rightButton addTarget:self action:@selector(okClick) forControlEvents:UIControlEventTouchUpInside];
        [view.rightButton setImage:[UIImage imageNamed:@"video_next"] forState:UIControlStateNormal];
        
        view.rightButton.hidden = YES;
        view.delegate = self;
        
        _upview = view;
        
    }
    return _upview;
}

- (SCRecorderToolsView *)focusView{
    if (!_focusView) {
        
        _focusView = [[SCRecorderToolsView alloc] initWithFrame:self.view.frame];
        _focusView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        _focusView.outsideFocusTargetImage = [UIImage imageNamed:@"capture_flip"];
        _focusView.insideFocusTargetImage = [UIImage imageNamed:@"capture_flip"];
        _focusView.recorder = _recorder;
        
    }
    return _focusView;
}

- (UIView *)previewView{
    if (!_previewView) {
        UIView *view = [UIView new];
        view.frame = self.view.frame;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGesture:)];
        longPress.minimumPressDuration = 0.2;
        [view addGestureRecognizer:longPress];
        
        UITapGestureRecognizer *tapPress = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapPressGesture:)];
        [view addGestureRecognizer:tapPress];
        
        UISwipeGestureRecognizer *leftswipeGe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePress:)];
        leftswipeGe.direction = UISwipeGestureRecognizerDirectionLeft;
        [view addGestureRecognizer:leftswipeGe];
        
        UISwipeGestureRecognizer *rightswipeGe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePress:)];
        [view addGestureRecognizer:rightswipeGe];
        
        _previewView = view;
    }
    return _previewView;
}

- (UILabel *)timeRecordedLabel{
    if (!_timeRecordedLabel) {
        
        UILabel *label = [UILabel new];
        label.frame = CGRectMake(self.view.frame.size.width - 100, 70, 80, 20);
        label.textColor = [UIColor whiteColor];
        label.text = @"0.00 sec";
        _timeRecordedLabel = label;
        
    }
    return _timeRecordedLabel;
}

#pragma mark - action

- (void)backClick{
    if (_recorder.session.segments.count>0) {
        [self resetUI];
    }else{
        [[TUMBProgressHUDManager sharedInstance] stoplodingNoAnimate];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)longPress{
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        if  (_videoType == videoTypeVideo)  {
            [[TUMBProgressHUDManager sharedInstance] stoploding];
            CCWeakObj(self)
            [[TUVideoManager sharedInstance] isCanRecorder:^(bool status) {
                CCStrongObj(self)
                if (!status) {
                    [[TUMBProgressHUDManager sharedInstance] showHUD:@"相机权限没有开启~"];
                    return ;
                }
                self.isRecord = YES;
                self.upview.leftButton.hidden = YES;
                self.upview.rightButton.hidden = YES;
                self.upview.tabView.hidden = YES;
                self.downView.hidden = YES;
                self.downView.deleteButton.selected = NO;
                self.isRecordering = YES;
                [self.recorder record];
            }];
            
        }
        
    } else if (longPress.state == UIGestureRecognizerStateEnded) {
        
        if (_videoType == videoTypeVideo) {
            if (self.isRecordering) {
                self.isRecordering = NO;
                self.upview.leftButton.hidden = NO;
                self.downView.hidden = NO;
                self.downView.deleteButton.hidden = NO;

                [self.recorder pause];
                
                if (CMTimeGetSeconds(_recorder.session.duration)>3) {
                    self.upview.rightButton.hidden = NO;
                }
                
                if (CMTimeGetSeconds(_recorder.session.duration)>0) {
                    [self.upview.leftButton setImage:[UIImage imageNamed:@"video_back"] forState:UIControlStateNormal];
                }
            }
        }
    }
}

- (void)tapPressGesture:(UITapGestureRecognizer *)tapPress{
    
    if (_videoType == videoTypeFlash) {
        if (_isRecordering) {
            return;
        }
        _isRecordering = YES;
        [[TUMBProgressHUDManager sharedInstance] stoploding];
        CCWeakObj(self)
        [[TUVideoManager sharedInstance] isCanRecorder:^(bool status) {
            CCStrongObj(self)
            if (!status) {
                [[TUMBProgressHUDManager sharedInstance] showHUD:@"相机权限没有开启~"];
                return ;
            }
            [self startFlashAnimation];
            self.upview.hidden = YES;
            self.downView.hidden = YES;
            [self.recorder record];
            
        }];
    }
    
}

- (void)swipePress:(UISwipeGestureRecognizer *)swipe{
    
    switch (swipe.direction) {
        case UISwipeGestureRecognizerDirectionRight:
            
            if (_videoType != videoTypeFlash) {
                [_upview swipeButton:2];
            }
            
            break;
        case UISwipeGestureRecognizerDirectionLeft :
           
            if (_videoType == videoTypeFlash) {
                [_upview swipeButton:1];
            }
            
            break;
        default:
            break;
    }
}

- (void)startFlashAnimation{
    
    self.flashImageView.hidden = NO;
    self.flashImageView.alpha = 0;
    _timer = [NSTimer timerWithTimeInterval:0.08 target:self selector:@selector(updateTimerAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    [_timer setFireDate:[NSDate distantPast]];
}

- (void)updateTimerAction{
    
    self.flashImageView.alpha = 1;
    [UIView animateWithDuration:0.05 animations:^{
        self.flashImageView.alpha = 0;
    }];
    
}

- (void)flashbuttonCick{
    if (_recorder.flashMode == SCFlashModeLight) {
        _recorder.flashMode = SCFlashModeOff;
        _downView.leftButton.selected = NO;
    }else{
        _recorder.flashMode = SCFlashModeLight;
        _downView.leftButton.selected = YES;
    }
}

- (void)frontorbackCick{
    if (_recorder.device == AVCaptureDevicePositionFront) {
        _recorder.device = AVCaptureDevicePositionBack;
        self.downView.leftButton.hidden = NO;
    }else{
        _recorder.device = AVCaptureDevicePositionFront;
        self.downView.leftButton.hidden = YES;
        self.downView.leftButton.selected = NO;
        _recorder.flashMode = SCFlashModeOff;
    }
}

- (void)deleteButtonClick:(UIButton *)button{
    
    if (button.selected) {
        
        [_recorder.session removeLastSegment];
        [self.upview deleteLastLine];
        button.selected = NO;
        
        if (_recorder.session.segments.count <= 0) {
            self.downView.deleteButton.hidden = YES;
            self.upview.tabView.hidden = NO;
        }
        
        if (CMTimeGetSeconds(_recorder.session.duration)<3) {
            self.upview.rightButton.hidden = YES;
        }
        
    }else{
        
        button.selected = YES;
        [self.upview redLastLine:(int)(_recorder.session.segments.count-1)];

    }
}

- (void)okClick{
    [self recordVideoEnd];
}

#pragma mark - recorderDelegate

- (void)recorder:(SCRecorder *)recorder didAppendVideoSampleBufferInSession:(SCRecordSession *)recordSession {
//    [self updateTimeRecordedLabel];
    [self isEndTime];
    
}


- (void)recorder:(SCRecorder *__nonnull)recorder didSkipAudioSampleBufferInSession:(SCRecordSession *__nonnull)session{
    NSLog(@"didSkipAudioSampleBufferInSession");
}

- (void)recorder:(SCRecorder *)recorder didCompleteSession:(SCRecordSession *)recordSession {
    NSLog(@"didCompleteSession:");
}

- (void)recorder:(SCRecorder *)recorder didInitializeAudioInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    if (error == nil) {
        NSLog(@"Initialized audio in record session");
    } else {
        NSLog(@"Failed to initialize audio in record session: %@", error.localizedDescription);
    }
}

- (void)recorder:(SCRecorder *)recorder didInitializeVideoInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    if (error == nil) {
        NSLog(@"Initialized video in record session");
    } else {
        NSLog(@"Failed to initialize video in record session: %@", error.localizedDescription);
    }
}

- (void)recorder:(SCRecorder *)recorder didBeginSegmentInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    NSLog(@"Began record segment: %@", error);
    float time = CMTimeGetSeconds(_recorder.session.duration);
    if (time >= _maxFrameDuration) {
        
    }
}

- (void)recorder:(SCRecorder *)recorder didCompleteSegment:(SCRecordSessionSegment *)segment inSession:(SCRecordSession *)recordSession error:(NSError *)error {
    NSLog(@"Completed record segment at %@: error:%@ (frameRate: %f)", segment.url, error, segment.frameRate);
    
    float time = CMTimeGetSeconds(_recorder.session.duration);
    
    if (_videoType == videoTypeVideo) {
        
        if (time >= _maxFrameDuration) {
            [[TUMBProgressHUDManager sharedInstance] stoplodingNoAnimate];
            return;
        }
        if (_isCompleted) {
            [[TUMBProgressHUDManager sharedInstance] stoploding];
            return;
        }
        if (time>3) {
            [[TUMBProgressHUDManager sharedInstance] showlongtimeHUD:@"长按屏幕，可继续录制"];
        }else{
            [[TUMBProgressHUDManager sharedInstance] showlongtimeHUD:@"视频过短，长按屏幕，继续录制"];
        }
        
    }

}

#pragma mark - upviewDelegate

- (void)tabButtonSelected:(videoType)selected{
    
    _videoType = selected;
    
    if (_videoType == videoTypeVideo) {
        self.isClickVideo = YES;
        _maxFrameDuration = kmaxtime;
        [[TUMBProgressHUDManager sharedInstance] showlongtimeHUD:@"长按屏幕，进行录制"];
    }else if (_videoType == videoTypeFlash) {
        _maxFrameDuration = 1.5;
        [[TUMBProgressHUDManager sharedInstance] showlongtimeHUD:@"单击屏幕，开始闪拍"];
        
    }

}

#pragma mark - delegate

- (void)previewReleaseSuccess{
    _isfirstcoming = YES;
}

- (void)editReleaseSuccess{
    _isfirstcoming = YES;
}


@end
