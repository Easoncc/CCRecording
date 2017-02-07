//
//  TUVideoManager.m
//  tataufo
//
//  Created by chenchao on 2016/12/7.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "TUVideoManager.h"
#import "SCRecordSession+TUHelp.h"
#import "TUMBProgressHUDManager.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreMedia/CoreMedia.h>


static int kdefaultFrameRate = 30;
static float kFlashFrameRate = 12;

@interface TUVideoManager()

@property (nonatomic ,strong) SCAssetExportSession *exportSession;
@property (nonatomic ,strong) NSURLSessionDataTask * networkManager;

@end

@implementation TUVideoManager

+ (TUVideoManager *)sharedInstance {
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
        self.frameRate = kdefaultFrameRate;
    }
    return self;
}

/**
 添加视频滤镜，全部合成保存
 
 recordSession 如果没有则不会和成全部视频，只合成滤镜视频便回调

 @param segmentsArray 需要加滤镜的视频源 格式：{segment：SCRecordSessionSegment，filter：SCFilter}
 @param complete 回调
 */
- (void)saveFilterVideoAndmerge:(NSArray *)segmentsArray complete:(videoComplete)complete{
    [self overSavewithArray:segmentsArray andIndex:0 complete:complete];
}

/**
 递归添加滤镜视频，全部合成保存

 @param array 视频源数组
 @param index 递归位置
 @param complete 回调
 */
- (void)overSavewithArray:(NSArray *)array andIndex:(int)index complete:(videoComplete)complete{
    
    NSDictionary *dic = [array objectAtIndex:index];
    SCRecordSessionSegment *oneSegment = [dic objectForKey:@"segment"];
    SCFilter *filter = [dic objectForKey:@"filter"];
    
    CCWeakObj(self)
    [self saveVideoWithAsset:oneSegment.asset andFilter:filter andURL:oneSegment.url complete:^(BOOL result) {
        CCStrongObj(self)
        if (array.count==index+1) {
            
            if (_recordSession) {
                [self saveVideoWithAsset:[_recordSession allAssetSegments] andFilter:nil andURL:_recordSession.outputUrl complete:complete];
            }else{
                if(complete) complete(YES);
            }
            
        }else{
            [self overSavewithArray:array andIndex:index+1 complete:complete];
        }
    }];
}


/**
 添加视频滤镜并保存

 @param asset 视频源
 @param filter 滤镜
 @param URL 输出url
 @param complete 回调
 */
- (void)saveVideoWithAsset:(AVAsset *)asset andFilter:(SCFilter *)filter andURL:(NSURL *)URL complete:(videoComplete)complete{
    [self saveVideoWithAsset:asset andFilter:filter andURL:URL andPreset:SCPresetMediumQuality complete:complete];
}

- (void)saveVideoWithAsset:(AVAsset *)asset andFilter:(SCFilter *)filter andURL:(NSURL *)URL andPreset:(NSString *)preset complete:(videoComplete)complete{
    
    [self saveVideoWithAsset:asset andFilter:filter andURL:URL andPreset:preset andWater:nil complete:complete];
    
//    SCAssetExportSession *exportSession = [[SCAssetExportSession alloc] initWithAsset:asset];
//    if (filter) exportSession.videoConfiguration.filter = filter;
//    exportSession.videoConfiguration.preset = preset;
//    exportSession.audioConfiguration.preset = SCPresetLowQuality;
//    exportSession.videoConfiguration.maxFrameRate = self.frameRate;
//    exportSession.outputUrl = URL;
//    exportSession.outputFileType = AVFileTypeMPEG4;
//    exportSession.contextType = SCContextTypeAuto;
//    
//    NSLog(@"Starting exporting");
//    NSLog(@"url....::::::%@",URL);
//    
//    CFTimeInterval time = CACurrentMediaTime();
//    __weak typeof(exportSession) weakExportSession = exportSession;
//    __weak typeof(self) weakSelf = self;
//    [exportSession exportAsynchronouslyWithCompletionHandler:^{
//        
//        __strong typeof(exportSession) strongExportSession = weakExportSession;
//        __strong typeof(self) strongSelf = weakSelf;
//        
//        [strongSelf resetManager];
//        
//        if (!strongExportSession.cancelled) {
//            NSLog(@"Completed ");
//            if (complete) complete(YES);
//        }else{
//            NSLog(@"Completed compression in %fs", CACurrentMediaTime() - time);
//            if (complete) complete(NO);
//        }
//        
//    }];
}

- (void)saveVideoWithAsset:(AVAsset *)asset andFilter:(SCFilter *)filter andURL:(NSURL *)URL andPreset:(NSString *)preset andWater:(UIImage *)waterImage complete:(videoComplete)complete{
    _exportSession = [[SCAssetExportSession alloc] initWithAsset:asset];
    if (filter) _exportSession.videoConfiguration.filter = filter;
    _exportSession.videoConfiguration.preset = preset;
    _exportSession.audioConfiguration.preset = SCPresetLowQuality;
    _exportSession.videoConfiguration.maxFrameRate = self.frameRate;
    _exportSession.outputUrl = URL;
    _exportSession.outputFileType = AVFileTypeMPEG4;
    _exportSession.contextType = SCContextTypeAuto;
    
    if (waterImage) {
        _exportSession.videoConfiguration.watermarkImage = waterImage;
        _exportSession.videoConfiguration.watermarkFrame = CGRectMake(20, 20, waterImage.size.width*2, waterImage.size.height*2);
        _exportSession.videoConfiguration.watermarkAnchorLocation = SCWatermarkAnchorLocationBottomRight;
    }
    
    NSLog(@"Starting exporting");
    NSLog(@"url....::::::%@",URL);
    
    CFTimeInterval time = CACurrentMediaTime();
    __weak typeof(self) weakSelf = self;
    [_exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf resetManager];
        
        if (!strongSelf.exportSession.cancelled) {
            NSLog(@"Completed ");
            if (complete) complete(YES);
        }else{
            NSLog(@"Completed compression in %fs", CACurrentMediaTime() - time);
//            if (complete) complete(NO);
        }
        
    }];
}

- (void)cancelExport{
    [_exportSession cancelExport];
}

// 还原
- (void)resetManager{
    self.recordSession = nil;
    self.frameRate = 30;
}

//图片合成视频
- (void)mergeFlashQuick:(NSArray *)array path:(NSString *)path block:(SuccessBlock)block{
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
     [HJImagesToVideo videoFromImages:array toPath:path withSize:CGSizeMake(720, 1280) withFPS:kFlashFrameRate*2 animateTransitions:NO withCallbackBlock:block];
}

- (void)movieToImage:(NSURL *)url block:(void (^)(NSArray *array))block{

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    generator.maximumSize = CGSizeMake(720, 1280);
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    
    NSMutableArray *timeArray = [NSMutableArray new];
    float scale = 600.0;
    float oneFrame = 1/kFlashFrameRate;
    int index = 0;
    float value = 0;
    while (index*oneFrame < CMTimeGetSeconds(asset.duration)) {
        CMTime thumbTime = CMTimeMake(value,scale);
        [timeArray addObject:[NSValue valueWithCMTime:thumbTime]];
        index++;
        value = index*oneFrame*scale;
    }
    NSMutableArray *photos = [NSMutableArray new];
    
    [generator generateCGImagesAsynchronouslyForTimes:timeArray completionHandler:^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            
            UIImage *thumbImg = [UIImage imageWithCGImage:im];
            [photos addObject:thumbImg];
            
            if (photos.count == timeArray.count) {
                
                NSMutableArray *images = [NSMutableArray arrayWithArray:photos];
                for (int i = (int)images.count-2; i >= 0; i--) {
                    [photos addObject:images[i]];
                }
                NSMutableArray *copyImages = [NSMutableArray arrayWithArray:photos];
                
                [photos addObjectsFromArray:copyImages];
                [photos addObjectsFromArray:copyImages];
                [photos addObjectsFromArray:copyImages];
                
                block(photos);
            }
//            NSLog(@"thummbimg :%f %f",thumbImg.size.width,thumbImg.size.height);
        }else{
            NSLog(@"error error error error error error ________________________");
        }
    }];
}


#pragma mark - 系统合成 暂时没用到
/**
 根据视频url 合成视频

 @param fileURLArray 视频url 数组
 @param URL 输出url
 @param complete 回调
 */
- (void)mergeAndExportVideosAtFileURLs:(NSArray *)fileURLArray outURL:(NSURL *)URL complete:(videoComplete)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        
        CGSize renderSize = CGSizeMake(0, 0);
        
        NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
        
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        
        CMTime totalDuration = kCMTimeZero;
        
        //先去assetTrack 也为了取renderSize
        NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
        NSMutableArray *assetArray = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileURLArray) {
            AVAsset *asset = [AVAsset assetWithURL:fileURL];
            
            if (!asset) {
                continue;
            }
            
            [assetArray addObject:asset];
            
            AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [assetTrackArray addObject:assetTrack];
            
            renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.height);
            renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.width);
        }
        
        CGFloat renderW = MIN(renderSize.width, renderSize.height);
        
        for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
            
            AVAsset *asset = [assetArray objectAtIndex:i];
            AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
            
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                 atTime:totalDuration
                                  error:nil];
            
            AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:assetTrack
                                 atTime:totalDuration
                                  error:&error];
            
            //fix orientationissue
            AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            totalDuration = CMTimeAdd(totalDuration, asset.duration);
            
            CGFloat rate;
            rate = renderW / MIN(assetTrack.naturalSize.width, assetTrack.naturalSize.height);
            
            CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
            layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0));//向上移动取中部影响
            layerTransform = CGAffineTransformScale(layerTransform, rate, rate);//放缩，解决前后摄像结果大小不对称
            
            [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
            [layerInstruciton setOpacity:0.0 atTime:totalDuration];
            
            //data
            [layerInstructionArray addObject:layerInstruciton];
        }
        
        //get save path
        NSURL *mergeFileURL = URL;
        
        //export
        AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
        mainInstruciton.layerInstructions = layerInstructionArray;
        AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
        mainCompositionInst.instructions = @[mainInstruciton];
        mainCompositionInst.frameDuration = CMTimeMake(1, 30);
        mainCompositionInst.renderSize = CGSizeMake(renderW, renderW);
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
        exporter.videoComposition = mainCompositionInst;
        exporter.outputURL = mergeFileURL;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(YES);
            });
        }];
    });
}

- (void)mergeAndExportVideos:(NSArray *)assetArray outURL:(NSURL *)URL complete:(videoComplete)complete{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        
        CMTime totalDuration = kCMTimeZero;
        
        //先去assetTrack 也为了取renderSize
        NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
        
        for (AVAsset *asset in assetArray) {
            
            AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [assetTrackArray addObject:assetTrack];
            
        }
        
        for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
            
            AVAsset *asset = [assetArray objectAtIndex:i];
            AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
            
            AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            CMTime duration = asset.duration;
            CMTime time = CMTimeMake(duration.value, duration.timescale*2.0);
            
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, time)
                                ofTrack:assetTrack
                                 atTime:totalDuration
                                  error:&error];
            
            totalDuration = CMTimeAdd(totalDuration, time);
            
        }
        
        //get save path
        NSURL *mergeFileURL = URL;
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
        exporter.outputURL = mergeFileURL;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(YES);
            });
        }];
    });
}

#pragma mark - 保存相册
//合成并存到本地
- (void)mergeAndsaveTolibraryWithAsset:(AVAsset *)asset andfilter:(SCFilter *)filter url:(NSURL *)url complete:(void (^)(NSError *))complete{
    
    NSString *documentsDirectory = NSTemporaryDirectory();
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"photoLibrary.mov"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    url = [NSURL fileURLWithPath:path];
    
    CCWeakObj(self)
    [self saveVideoWithAsset:asset andFilter:filter andURL:url andPreset:SCPresetHighestQuality andWater:[UIImage imageNamed:@"video_water"] complete:^(BOOL result) {
        CCStrongObj(self)
        [self saveTolibrary:url complete:^(NSError *_error) {
            if (complete) complete(_error);
        }];
        
    }];
}

/**
 保存到相册

 @param url url
 @param complete 回调
 */
- (void)saveTolibrary:(NSURL *)url complete:(void (^)(NSError *_error))complete{
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [url saveToCameraRollWithCompletion:^(NSString * _Nullable path, NSError * _Nullable error) {
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        if (complete) complete(error);
        
    }];
    
}

#pragma mark 相机权限

- (void)isCanRecorder:(void (^)(bool status))complete{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
                if (granted) {
                    //第一次用户接受
                    if (complete) complete(YES);
                    
                }else{
                    //用户拒绝
                    if (complete) complete(NO);
                }
            }];
            
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续
            if (complete) complete(YES);
            
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            if (complete) complete(NO);
            break;
        default:
            break;
    }
}

#pragma mark - 清理空间

- (void)removetmpobjects{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *extension = @"mov";
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsDirectory = NSTemporaryDirectory();
        
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
        NSEnumerator *enumerator = [contents objectEnumerator];
        NSString *filename;
        while ((filename = [enumerator nextObject])) {
            if ([[filename pathExtension] isEqualToString:extension]) {
                [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:nil];
            }
        }
    });
    
}
#pragma mark - 发布
- (void)uploadVideoWithURL:(NSURL *)url andtype:(int)type images:(NSArray *)images block:(void (^)())complete{
    
//    _networkManager = [[TUNetWorkManager sharedInstance] image_UploadPath:CONTENT ImagesArray:images withSuffixStr:@""  Success:^(NSMutableArray *imageUrlArray, BOOL isSuccess) {
//        
//        [[TUNetWorkManager sharedInstance] video_UploadPath:CONTENT videoPath:url withSuffixStr:@"" progressHandler:^(NSURL *filePathUrl, float percent) {
////            NSLog(@"percent :%f",percent);
//        } Success:^(NSString *url, BOOL success) {
//            if (success) {
//                [[TUNetWorkManager sharedInstance] releaseTopicWithTopicInfos:nil body:@"" mediaUrlsArray:imageUrlArray permit:self.powerPermit flashURL:url type:type  success:^(NSDictionary *data) {
//                    if (complete) {
//                        complete();
//                    }
//                    [[TUMBProgressHUDManager sharedInstance] showHUD:@"发布成功~"];
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [[UIViewController currentViewController].navigationController popToRootViewControllerAnimated:YES];
//                    });
//                    
//                } failure:^(NSError *error) {
//                    
//                    [[TUMBProgressHUDManager sharedInstance] showHUDError:error];
//                }];
//            }else{
//               [[TUMBProgressHUDManager sharedInstance] showHUD:@"上传失败~"];
//            }
//            
//            
//        } failure:^(NSError *error) {
//            
//            [[TUMBProgressHUDManager sharedInstance] showHUDError:error];
//        }];
//        
//    } failure:^(NSError *error) {
//         [[TUMBProgressHUDManager sharedInstance] showHUDError:error];
//    }];

}

- (void)cancelUploadVideo{
    [_networkManager cancel];
    
}

#pragma mark - 图片合成视频

-(void)testCompressionSession:(NSString *)path size:(CGSize)size images:(NSArray *)imageArr
{
    NSLog(@"开始");
    NSError *error;
    AVAssetWriter *videoWriter =[[AVAssetWriter alloc]initWithURL:[NSURL fileURLWithPath:path]
                                                        fileType:AVFileTypeQuickTimeMovie
                                                           error:&error];
    NSParameterAssert(videoWriter);
    if(error)
        NSLog(@"error =%@", [error localizedDescription]);
    
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,
                                  [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                  [NSNumber numberWithInt:size.height],AVVideoHeightKey,nil];
    AVAssetWriterInput *writerInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary *sourcePixelBufferAttributesDictionary =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor
                                                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    if ([videoWriter canAddInput:writerInput])
        NSLog(@"11111");
    else
        NSLog(@"22222");
    
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue =dispatch_queue_create("mediaInputQueue",NULL);
    int __block frame =0;
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while([writerInput isReadyForMoreMediaData])
        {
            if(++frame >= [imageArr count]*10)
            {
                [writerInput markAsFinished];
//                [videoWriter finishWriting];
                [videoWriter finishWritingWithCompletionHandler:^{
                    
                }];
                //              [videoWriterfinishWritingWithCompletionHandler:nil];
                break;
            }
            
            CVPixelBufferRef buffer =NULL;
            
            int idx = frame/10;
            NSLog(@"idx==%d",idx);
            
            buffer =(CVPixelBufferRef)[self pixelBufferFromCGImage:[[imageArr objectAtIndex:idx] CGImage] size:size];
            
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame,10)])
                    NSLog(@"FAIL");
                else
                    NSLog(@"OK");
                CFRelease(buffer);
            }
        }
    }];
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);   
    
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);   
    
    return pxbuffer;  
}


@end
