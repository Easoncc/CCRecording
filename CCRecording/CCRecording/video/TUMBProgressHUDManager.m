//
//  TUMBProgressHUDManager.m
//  tataufo
//
//  Created by chenchao on 2016/12/19.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUMBProgressHUDManager.h"

@interface TUMBProgressHUDManager()

@property (nonatomic ,strong) CCProgressHUD *progressHUD;

@end

@implementation TUMBProgressHUDManager

+ (TUMBProgressHUDManager *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
    }
    return self;
}


- (CCProgressHUD *)getMBProgress{
    return [CCProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
}
#pragma mark - hud

- (void)showLodingWithText:(NSString *)text{
    _progressHUD =  [self getMBProgress];
    _progressHUD.label.text = text;
    [_progressHUD showAnimated:YES];
}

- (void)showLoding{
    _progressHUD =  [self getMBProgress];
    _progressHUD.mode = CCProgressHUDModeIndeterminate;
    _progressHUD.label.text = @"";
    [_progressHUD showAnimated:YES];
}

- (void)stoploding{
    [_progressHUD hideAnimated:YES];
}

- (void)stoplodingNoAnimate{
    [_progressHUD hideAnimated:NO];
}

- (void)showlongtimeHUD:(NSString *)text{
    [self stoploding];
    _progressHUD =  [self getMBProgress];
    _progressHUD.bezelView.style = CCProgressHUDBackgroundStyleSolidColor;
    _progressHUD.bezelView.color = [UIColor clearColor];
    _progressHUD.mode = CCProgressHUDModeText;
    
    _progressHUD.offset = CGPointMake(0, KDeviceHeight/2.0-80);
    _progressHUD.label.text = text;
    _progressHUD.label.font = [UIFont systemFontOfSize:19.0];
    _progressHUD.label.textColor = [UIColor whiteColor];
    _progressHUD.userInteractionEnabled = NO;

}

- (void)showNOCameraHUD{
    [self stoploding];
    _progressHUD =  [self getMBProgress];
    _progressHUD.mode = CCProgressHUDModeText;
    
    _progressHUD.label.text = @"相机权限没有开启~";
    _progressHUD.userInteractionEnabled = NO;
    
}

- (void)showHUD:(NSString *)text{
    [self stoploding];
    _progressHUD =  [self getMBProgress];
    _progressHUD.mode = CCProgressHUDModeText;
    _progressHUD.label.text = text;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self stoploding];
    });
}

- (void)showHUDError:(NSError *)error{
    NSError *tmp = (NSError *)error;
    NSString *errmsg ;
    if(tmp.code == -999)
    {
        return;
    }
    NSDictionary *errorContent = tmp.userInfo;
    NSError *errorRealContent = [errorContent objectForKey:@"NSUnderlyingError"];
    if (errorRealContent) {
        NSLog(@"error received:%@", [errorRealContent localizedDescription]);
        if (errorRealContent.code == -1009) {
            errmsg = @"网络貌似有问题啊~";
        }else{
            errmsg = @"服务器暂时无法访问";
        }
    } else {
        errmsg = [error localizedDescription];
    }
    [self showHUD:errmsg];
}


@end
