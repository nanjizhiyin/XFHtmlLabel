//
//  CoreTextView.h
//  TEST_ATTR_002
//
//  Created by cxjwin on 13-7-29.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

@protocol XXHtmlViewDelegate;
@class XXHtmlString;

@interface XXHtmlView : UIView
{
    CTFrameRef                      _textFrame;//整个画布
    
    BOOL                            _isClickLink;//是否点中了超链接
    NSRange                         _linkRange;//当前选中的超链接的range
    NSString                        *_linkUrl;//连接地址
    
    NSMutableAttributedString       *_attributedString;
}
@property (assign, nonatomic) id<XXHtmlViewDelegate> delegate;
@property(nonatomic,assign)UIEdgeInsets             edgeInsets;//内边距

@property(nonatomic,assign) BOOL                       canTap;//支持点击后变色
@property(nonatomic,assign) BOOL                       analyseHref;//支持href超链接解析
@property(nonatomic,assign) BOOL                       analyseLink;//支持超链接解析
@property(nonatomic,assign) CTLineBreakMode             lineBreak;//换行模式
@property(nonatomic,retain) UIColor                    *backgroundColorNormal;//点击前的默认背景色
@property(nonatomic,retain) UIColor                    *backgroundColorHighlighted;//点击时的背景色
@property(nonatomic,retain) UIFont                     *font;//文字的默认font
@property(nonatomic,retain) UIColor                     *textColor;       // default is nil (text draws black)

@property(nonatomic,assign)BOOL                         openCopy;//打开复制功能
@property(nonatomic)       SEL                          copyAction;    // default is NULL
@property(nonatomic,copy)   NSString                    *textCopy;//要复制的文字

@property(nonatomic,copy)   NSString                    *htmlText;
@property(nonatomic,copy)   XXHtmlString                *htmlString;

@property (nonatomic)       CGSize                      adjustSize;//文字内容的大小,不是控件的实际大小

//在指定位置添加一个图片
- (void)replaceImageName:(NSString *)imageName atIndex:(NSInteger)loc;

//自动适应大小
- (void)sizeToHtmlFit;

- (void)sizeToHtmlFitWithMinWith:(CGFloat)minWidth;


@end


@protocol XXHtmlViewDelegate <NSObject>
@optional

- (void)htmlView:(XXHtmlView *)htmlView withURL:(NSString *)url;//点击了超链接
- (void)htmlView:(XXHtmlView *)htmlView tap:(UITapGestureRecognizer *)sender;//点击事件
- (void)htmlView:(XXHtmlView *)htmlView longPress:(UILongPressGestureRecognizer*) recognizer;//长按事件开始和结束
- (void)htmlView:(XXHtmlView *)htmlView doubleTap:(UITapGestureRecognizer*) recognizer;//双击事件

@end