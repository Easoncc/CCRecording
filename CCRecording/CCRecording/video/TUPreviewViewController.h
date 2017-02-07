//
//  playViewController.h
//  videoTest
//
//  Created by chenchao on 2016/12/2.
//  Copyright © 2016年 chenchao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRecorder.h"

@protocol TUPreviewViewControllerDelegate <NSObject>

- (void)previewReleaseSuccess;

@end

@interface TUPreviewViewController : UIViewController

@property (strong, nonatomic) SCRecordSession *recordSession;
@property (weak ,nonatomic) id<TUPreviewViewControllerDelegate> delegate;
@end
