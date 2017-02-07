//
//  TUColorView.h
//  tataufo
//
//  Created by chenchao on 2016/12/13.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TUColorViewDelegate <NSObject>

- (void)tapColor:(UIColor *)color;

@end

@interface TUColorView : UIView

@property (nonatomic ,weak) id<TUColorViewDelegate> delegate;

@end
