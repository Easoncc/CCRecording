//
//  AVAsset+help.m
//  tataufo
//
//  Created by chenchao on 2016/12/16.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "AVAsset+help.h"

@implementation AVAsset (help)

+ (AVAsset *)mergeAllAvasset:(NSArray *)assetArray{
    AVMutableComposition *composition = [AVMutableComposition composition];
    [AVAsset tuappendSegmentsToComposition:composition andArray:assetArray];
    AVAsset *asset = composition;
    return  asset;
}

+ (void)tuappendSegmentsToComposition:(AVMutableComposition *)composition andArray:(NSArray *)assetArray{
    
        AVMutableCompositionTrack *audioTrack = nil;
        AVMutableCompositionTrack *videoTrack = nil;
        
        int currentSegment = 0;
        CMTime currentTime = composition.duration;
        for (AVAsset *asset in assetArray) {

            NSArray *audioAssetTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            NSArray *videoAssetTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            
            CMTime maxBounds = kCMTimeInvalid;
            
            CMTime videoTime = currentTime;
            for (AVAssetTrack *videoAssetTrack in videoAssetTracks) {
                if (videoTrack == nil) {
                    NSArray *videoTracks = [composition tracksWithMediaType:AVMediaTypeVideo];
                    
                    if (videoTracks.count > 0) {
                        videoTrack = [videoTracks firstObject];
                    } else {
                        videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                        videoTrack.preferredTransform = videoAssetTrack.preferredTransform;
                    }
                }
                
                videoTime = [AVAsset _appendTrack:videoAssetTrack toCompositionTrack:videoTrack atTime:videoTime withBounds:maxBounds];
                maxBounds = videoTime;
            }
            
            CMTime audioTime = currentTime;
            for (AVAssetTrack *audioAssetTrack in audioAssetTracks) {
                if (audioTrack == nil) {
                    NSArray *audioTracks = [composition tracksWithMediaType:AVMediaTypeAudio];
                    
                    if (audioTracks.count > 0) {
                        audioTrack = [audioTracks firstObject];
                    } else {
                        audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                    }
                }
                
                audioTime = [AVAsset _appendTrack:audioAssetTrack toCompositionTrack:audioTrack atTime:audioTime withBounds:maxBounds];
            }
            
            currentTime = composition.duration;
            
            currentSegment++;
        }
    
}

+ (CMTime)_appendTrack:(AVAssetTrack *)track toCompositionTrack:(AVMutableCompositionTrack *)compositionTrack atTime:(CMTime)time withBounds:(CMTime)bounds {
    CMTimeRange timeRange = track.timeRange;
    time = CMTimeAdd(time, timeRange.start);
    
    if (CMTIME_IS_VALID(bounds)) {
        CMTime currentBounds = CMTimeAdd(time, timeRange.duration);
        
        if (CMTIME_COMPARE_INLINE(currentBounds, >, bounds)) {
            timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(timeRange.duration, CMTimeSubtract(currentBounds, bounds)));
        }
    }
    
    if (CMTIME_COMPARE_INLINE(timeRange.duration, >, kCMTimeZero)) {
        NSError *error = nil;
        [compositionTrack insertTimeRange:timeRange ofTrack:track atTime:time error:&error];
        
        if (error != nil) {
            NSLog(@"Failed to insert append %@ track: %@", compositionTrack.mediaType, error);
        } else {
            //        NSLog(@"Inserted %@ at %fs (%fs -> %fs)", track.mediaType, CMTimeGetSeconds(time), CMTimeGetSeconds(timeRange.start), CMTimeGetSeconds(timeRange.duration));
        }
        
        return CMTimeAdd(time, timeRange.duration);
    }
    
    return time;
}

#pragma mark - 倒序
+ (void)doFlashwithAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL complete:(void (^)())complete error:(void (^)(NSError *error))completError{
    
    NSError *error;
    
    // Initialize the reader
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    NSDictionary *readerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], kCVPixelBufferPixelFormatTypeKey, nil];
    AVAssetReaderTrackOutput* readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                                        outputSettings:readerOutputSettings];
    [reader addOutput:readerOutput];
    [reader startReading];
    
    if (error) {
        completError(error);
        return;
    }
    
    // read in the samples
    NSMutableArray *samples = [[NSMutableArray alloc] init];
    
    CMSampleBufferRef sample;
    while((sample = [readerOutput copyNextSampleBuffer])) {
        [samples addObject:(__bridge id)sample];
        CFRelease(sample);
    }
    
    if (samples.count==0) {
        NSError *errors = [NSError errorWithDomain:@"合成失败" code:10101 userInfo:@{NSLocalizedDescriptionKey:@"合成失败"}];
        completError(errors);
        return;
    }
    
    // Initialize the writer
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:outputURL
                                                      fileType:AVFileTypeMPEG4
                                                         error:&error];
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @(videoTrack.estimatedDataRate), AVVideoAverageBitRateKey,
                                           nil];
    NSDictionary *writerOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          AVVideoCodecH264, AVVideoCodecKey,
                                          [NSNumber numberWithInt:videoTrack.naturalSize.width], AVVideoWidthKey,
                                          [NSNumber numberWithInt:videoTrack.naturalSize.height], AVVideoHeightKey,
                                          videoCompressionProps, AVVideoCompressionPropertiesKey,
                                          nil];
    AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                     outputSettings:writerOutputSettings
                                                                   sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
    [writerInput setExpectsMediaDataInRealTime:NO];
    
    // Initialize an input adaptor so that we can append PixelBuffer
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    [writer addInput:writerInput];
    [writer startWriting];
    [writer startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[0])];
    
    for(NSInteger i = 0; i < samples.count; i++) {
        // Get the presentation time for the frame
        CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples[i]);
        // take the image/pixel buffer from tail end of the array
        CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples[samples.count - i - 1]);
        
        while (!writerInput.readyForMoreMediaData) {
            [NSThread sleepForTimeInterval:0.1];
        }
        [pixelBufferAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:presentationTime];
    }
    
    [writer finishWritingWithCompletionHandler:complete];
    
}

#pragma mark - 闪拍数据 去除声音

+(AVAsset *)mergeFlashAvasset:(NSArray *)assetArray{
    AVMutableComposition *composition = [AVMutableComposition composition];
    [AVAsset addFlashToComposition:composition andArray:assetArray];
    AVAsset *asset = composition;
    return  asset;
}

+ (void)addFlashToComposition:(AVMutableComposition *)composition andArray:(NSArray *)assetArray{
    
    AVMutableCompositionTrack *videoTrack = nil;
    
    int currentSegment = 0;
    CMTime currentTime = composition.duration;
    for (AVAsset *asset in assetArray) {
    
        NSArray *videoAssetTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        
        CMTime maxBounds = kCMTimeInvalid;
        
        CMTime videoTime = currentTime;
        for (AVAssetTrack *videoAssetTrack in videoAssetTracks) {
            if (videoTrack == nil) {
                NSArray *videoTracks = [composition tracksWithMediaType:AVMediaTypeVideo];
                
                if (videoTracks.count > 0) {
                    videoTrack = [videoTracks firstObject];
                } else {
                    videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                    videoTrack.preferredTransform = videoAssetTrack.preferredTransform;
                }
            }
            
            videoTime = [AVAsset _appendTrack:videoAssetTrack toCompositionTrack:videoTrack atTime:videoTime withBounds:maxBounds];
            maxBounds = videoTime;
        }
        
        currentTime = composition.duration;
        
        currentSegment++;
    }
    
}
#pragma mark - 获取视频略缩图
+ (UIImage *)thumbnail:(AVAsset *)asset{
    UIImage *image = nil;
    if (image == nil) {
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        
        NSError *error = nil;
        CGImageRef thumbnailImage = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:nil error:&error];
        
        if (error == nil) {
            image = [UIImage imageWithCGImage:thumbnailImage];
        } else {
            NSLog(@"Unable to generate thumbnail for  %@",  error.localizedDescription);
        }
    }
    
    return image;
}


@end
