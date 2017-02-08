//
//  TUVideoUpView.h
//  tataufo
//
//  Created by chenchao on 2016/12/8.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRecorder.h"
typedef enum {
    videoTypeVideo = 0  ,
    videoTypeFlash,
}videoType;

@protocol TUVideoUpViewDelegate <NSObject>

- (void)tabButtonSelected:(videoType)selected;

@end

@interface TUVideoUpView : UIView

@property (nonatomic ,strong ,readonly) UIButton *leftButton;
@property (nonatomic ,strong ,readonly) UIButton *rightButton;
@property (nonatomic ,strong ,readonly) UIButton *saveButton;
@property (nonatomic ,strong ,readonly) UIButton *powerButton;

@property (nonatomic ,strong ,readonly) UIView *tabView;
@property (nonatomic ,assign) BOOL havePermitButton;

@property (nonatomic ,weak) id<TUVideoUpViewDelegate> delegate;
@property (nonatomic ,assign) float maxtime;

@property (nonatomic ,strong) SCRecordSession *session;

- (void)redLastLine:(int)index;
- (void)deleteLastLine;
- (void)resetLine;
- (void)swipeButton:(int)index;

@end
