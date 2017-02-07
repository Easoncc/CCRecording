//
//  NSString+Size.m
//  intraSame
//
//  Created by howeguo on 2/18/16.
//  Copyright (c) 2016 tataUFO. All rights reserved.
//

#import "NSString+Size.h"

@implementation NSString (Size)

- (CGFloat) getTextWidthWithMaxHeight:(CGFloat) maxHeight andFont:(UIFont *) font
{
    NSDictionary *attribute = @{NSFontAttributeName:font};
    CGSize size = [self boundingRectWithSize:CGSizeMake(MAXFLOAT, maxHeight) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
    return ceilf(size.width);
}

- (CGFloat) getTextHeightWithMaxWidth:(CGFloat) maxWidth andFont:(UIFont *) font
{
    NSDictionary *attribute = @{NSFontAttributeName:font};
    CGSize size = [self boundingRectWithSize:CGSizeMake(maxWidth,MAXFLOAT) options:NSStringDrawingTruncatesLastVisibleLine |  NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin  attributes:attribute context:nil].size;
    return ceilf(size.height);
    
}

- (CGSize) getTextSizeWithMaxWidth:(CGFloat) maxWidth MaxHeight:(CGFloat) maxHeight andFont:(UIFont *) font
{
    NSDictionary *attribute = @{NSFontAttributeName:font};
    CGSize size = [self boundingRectWithSize:CGSizeMake(maxWidth,maxHeight) options:NSStringDrawingTruncatesLastVisibleLine |  NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin  attributes:attribute context:nil].size;
    return size;
    
}


@end
