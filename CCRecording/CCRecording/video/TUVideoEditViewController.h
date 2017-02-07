//
//  TUVideoEditViewController.h
//  tataufo
//
//  Created by chenchao on 2016/12/5.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRecorder.h"

typedef enum {
    videoEditTypeNo = 0  ,
    videoEditTypePicture,
    videoEditTypeText,
}videoEditType;

@protocol TUVideoEditViewControllerDelegate <NSObject>

- (void)videoAssetisChange;
- (void)editReleaseSuccess;
@end

@interface TUVideoEditViewController : UIViewController

@property (nonatomic ,strong) SCRecordSessionSegment *segment;
@property (nonatomic ,assign) videoEditType editStatus;
@property (nonatomic ,assign) BOOL isFlash;
@property (nonatomic ,weak) id<TUVideoEditViewControllerDelegate> delegate;

@end
