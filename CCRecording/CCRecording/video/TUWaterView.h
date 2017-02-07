//
//  TUWaterView.h
//  tataufo
//
//  Created by chenchao on 2016/12/5.
//  Copyright © 2016年 tataufo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCVideoConfiguration.h"

@interface TUWaterView : UIView<SCVideoOverlay>

- (void)setImage:(UIImage *)image;

@end
