//
//  TUVideoTextImageView.h
//  tataufo
//
//  Created by chenchao on 2016/12/14.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TUVideoTextImageViewDelegate <NSObject>

- (void)panBeginPointdSender:(id)sender;
- (void)panMovePoint:(CGPoint)point andSender:(id)sender;
- (void)panEndPoint:(CGPoint)point andSender:(id)sender;
- (void)tapImageToEdit:(id)sender;

@end

@interface TUVideoTextImageView : UIImageView

@property (nonatomic ,weak) id<TUVideoTextImageViewDelegate> delegate;
@property (nonatomic ,strong) NSString *text;
@property (nonatomic ,assign) float rotation;
@property (nonatomic ,assign) float scale;
@property (nonatomic ,assign) CGPoint offsetPoint;

@end
