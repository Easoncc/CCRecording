//
//  TUVideoManager.h
//  tataufo
//
//  Created by chenchao on 2016/12/7.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCRecorder.h"
#import "HJImagesToVideo.h"

typedef void (^videoComplete)(BOOL result);

@interface TUVideoManager : NSObject

+ (TUVideoManager *)sharedInstance;

@property (nonatomic ,assign) CMTimeScale frameRate;
@property (nonatomic ,strong) SCRecordSession *recordSession;
@property (nonatomic ,assign) NSInteger powerPermit;

- (void)saveFilterVideoAndmerge:(NSArray *)segmentsArray complete:(videoComplete)complete;

- (void)saveVideoWithAsset:(AVAsset *)asset andFilter:(SCFilter *)filter andURL:(NSURL *)URL complete:(videoComplete)complete;
- (void)saveVideoWithAsset:(AVAsset *)asset andFilter:(SCFilter *)filter andURL:(NSURL *)URL andPreset:(NSString *)preset complete:(videoComplete)complete;

- (void)mergeAndsaveTolibraryWithAsset:(AVAsset *)asset andfilter:(SCFilter *)filter url:(NSURL *)url complete:(void (^)(NSError *))complete;
- (void)mergeAndExportVideos:(NSArray *)assetArray outURL:(NSURL *)URL complete:(videoComplete)complete;

- (void)saveTolibrary:(NSURL *)url complete:(void (^)(NSError *_error))complete;
//相机权限是否开启
- (void)isCanRecorder:(void (^)(bool status))complete;
- (void)removetmpobjects;

- (void)uploadVideoWithURL:(NSURL *)url andtype:(int)type images:(NSArray *)images block:(void (^)())complete;

- (void)movieToImage:(NSURL *)url block:(void (^)(NSArray *array))block;
//图片合成视频
- (void)mergeFlashQuick:(NSArray *)array path:(NSString *)path block:(SuccessBlock)block;

- (void)cancelExport;
- (void)cancelUploadVideo;
@end
