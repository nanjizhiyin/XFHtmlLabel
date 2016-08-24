//
//  NSString+Weibo.h
//  CoreTextDemo
//
//  Created by cxjwin on 13-10-31.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>


extern NSString *const kXXCustomGlyphAttributeType;
extern NSString *const kXXCustomGlyphAttributeRange;
extern NSString *const kXXCustomGlyphAttributeImageName;
extern NSString *const kXXCustomGlyphAttributeInfo;

//内容类型
typedef enum XXCustomGlyphAttributeType {
    XXCustomGlyphAttributeURL = 0,
    XXCustomGlyphAttributeImage,
    XXCustomGlyphAttributeInfoImage,// 预留，给带相应信息的图片（如点击图片获取相关属性）
}XXCustomGlyphAttributeType;

//图片的宽度
typedef struct XXCustomGlyphMetrics {
    CGFloat ascent;
    CGFloat descent;
    CGFloat width;
}XXCustomGlyphMetrics, *XXCustomGlyphMetricsRef;

@interface XXHtmlString : NSObject<NSMutableCopying>
{
    
}

@property(nonatomic,retain)NSMutableDictionary             *links;//所有的链接地址key:文字的起始位置,value连接地址
@property(nonatomic,copy)NSString                       *string;
@property(nonatomic,retain)NSMutableAttributedString      *attributedString;

//不用复制的数据
@property(nonatomic,retain)UIFont                       *font;
@property(nonatomic,retain)UIColor                       *textColor;
@property(nonatomic,assign) BOOL                       analyseHref;//支持href超链接解析
@property(nonatomic,assign) BOOL                       analyseLink;//支持超链接解析
@property(nonatomic,assign) CTLineBreakMode             lineBreak;//换行模式


- (void)transformText:(NSString *)text;

//在指定位置添加一个图片
- (void)replaceImageName:(NSString *)imageName atIndex:(NSInteger)loc;

//读取文字的高度
+ (CGSize)sizeWithString:(NSString *)string
            withMaxWidth:(CGFloat)maxWidth
                withFont:(UIFont *)font;


//读取文字的高度
+ (CGSize)sizeWithString:(NSAttributedString *)attributedString
            withMaxWidth:(CGFloat)maxWidth;

@end
