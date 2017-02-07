//
//  TUVideoPreviewDownView.h
//  tataufo
//
//  Created by chenchao on 2016/12/10.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRecorder.h"

@protocol TUVideoPreviewDownViewDelegate <NSObject>

- (void)pickoneVideo:(int)index;
- (void)pickEnd;

@end

@interface TUVideoPreviewDownView : UIView

@property (nonatomic ,strong ,readonly) UIScrollView *scrollView;

@property (nonatomic ,strong) SCRecordSession *session;

@property (nonatomic ,weak) id<TUVideoPreviewDownViewDelegate> delegate;

- (void)scrollToindex:(int)index;
- (void)resetImageView:(int)index andImage:(UIImage *)image;
@end
