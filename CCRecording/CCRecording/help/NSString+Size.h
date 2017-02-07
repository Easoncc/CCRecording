//
//  NSString+Size.h
//  intraSame
//
//  Created by howeguo on 2/18/16.
//  Copyright (c) 2016 tataUFO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Size)
- (CGFloat) getTextWidthWithMaxHeight:(CGFloat) maxHeight andFont:(UIFont *) font;
- (CGFloat) getTextHeightWithMaxWidth:(CGFloat) maxWidth andFont:(UIFont *) font;
- (CGSize) getTextSizeWithMaxWidth:(CGFloat) maxWidth MaxHeight:(CGFloat) maxHeight andFont:(UIFont *) font;
@end
