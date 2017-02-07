//
//  SCRecordSession+TUHelp.m
//  tataufo
//
//  Created by chenchao on 2016/12/7.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import "SCRecordSession+TUHelp.h"

@implementation SCRecordSession (TUHelp)

- (AVAsset *)allAssetSegments{
    __block AVAsset *asset = nil;
    [self dispatchSyncOnSessionQueue:^{
        if (self.segments.count == 1) {
            SCRecordSessionSegment *segment = self.segments.firstObject;
            asset = [AVAsset assetWithURL:segment.url];
        } else {
            AVMutableComposition *composition = [AVMutableComposition composition];
            [self tuappendSegmentsToComposition:composition audioMix:nil];
            asset = composition;
        }
    }];
    
    return asset;
}

- (void)tuappendSegmentsToComposition:(AVMutableComposition *)composition audioMix:(AVMutableAudioMix *)audioMix {
    [self dispatchSyncOnSessionQueue:^{
        AVMutableCompositionTrack *audioTrack = nil;
        AVMutableCompositionTrack *videoTrack = nil;
        
        int currentSegment = 0;
        CMTime currentTime = composition.duration;
        for (SCRecordSessionSegment *recordSegment in self.segments) {
            
            AVAsset *asset = [AVAsset assetWithURL:recordSegment.url];
            if (!asset) {
                asset = recordSegment.asset;
            }
            
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
                
                videoTime = [self _appendTrack:videoAssetTrack toCompositionTrack:videoTrack atTime:videoTime withBounds:maxBounds];
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
                
                audioTime = [self _appendTrack:audioAssetTrack toCompositionTrack:audioTrack atTime:audioTime withBounds:maxBounds];
            }
            
            currentTime = composition.duration;
            
            currentSegment++;
        }
    }];
}

- (CMTime)_appendTrack:(AVAssetTrack *)track toCompositionTrack:(AVMutableCompositionTrack *)compositionTrack atTime:(CMTime)time withBounds:(CMTime)bounds {
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

@end
