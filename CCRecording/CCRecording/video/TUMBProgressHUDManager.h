//
//  TUMBProgressHUDManager.h
//  tataufo
//
//  Created by chenchao on 2016/12/19.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCProgressHUD.h"

@interface TUMBProgressHUDManager : NSObject

+ (TUMBProgressHUDManager *)sharedInstance;

- (void)showLoding;
- (void)stoploding;
- (void)stoplodingNoAnimate;
- (void)showNOCameraHUD;
- (void)showHUD:(NSString *)text;
- (void)showlongtimeHUD:(NSString *)text;
- (void)showHUDError:(NSError *)error;
- (void)showLodingWithText:(NSString *)text;

@end
