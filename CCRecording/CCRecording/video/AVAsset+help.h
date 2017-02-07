//
//  AVAsset+help.h
//  tataufo
//
//  Created by chenchao on 2016/12/16.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVAsset (help)

//正常视频
+ (AVAsset *)mergeAllAvasset:(NSArray *)assetArray;
//闪拍去声音
+(AVAsset *)mergeFlashAvasset:(NSArray *)assetArray;
//视频倒序
+ (void)doFlashwithAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL complete:(void (^)())complete error:(void (^)(NSError *error))completError;
//获取视频略缩图
+ (UIImage *)thumbnail:(AVAsset *)asset;

@end
