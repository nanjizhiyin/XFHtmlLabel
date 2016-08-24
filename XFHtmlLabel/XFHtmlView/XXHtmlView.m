//
//  CoreTextView.m
//  TEST_ATTR_002
//
//  Created by cxjwin on 13-7-29.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import "XXHtmlView.h"
#import "XXHtmlString.h"

@implementation XXHtmlView

- (id)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _canTap = YES;
        _isClickLink = FALSE;
        
        _analyseLink = YES;
        _analyseHref = YES;
        
        _htmlString = [[XXHtmlString alloc] init];
        _attributedString = [[NSMutableAttributedString alloc] init];
    }
    return self;
}
- (void)setAnalyseHref:(BOOL)analyseHref
{
    _analyseHref = analyseHref;
    _htmlString.analyseHref = analyseHref;
}
- (void)setAnalyseLink:(BOOL)analyseLink
{
    _analyseLink = analyseLink;
    _htmlString.analyseLink = analyseLink;
}
- (void)setLineBreak:(CTLineBreakMode)lineBreak
{
    _lineBreak = lineBreak;
    _htmlString.lineBreak = lineBreak;
}
//设置代理
- (void)setDelegate:(id<XXHtmlViewDelegate>)delegate
{
    _delegate = delegate;
    
    self.userInteractionEnabled = YES;  //用户交互的总开关
    UITapGestureRecognizer *singleOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    singleOne.numberOfTouchesRequired = 1;    //触摸点个数，另作：[singleOne setNumberOfTouchesRequired:1];
    singleOne.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleOne];
    [singleOne release];
    
    //长按
    UILongPressGestureRecognizer* gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];
    
    //双击
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTapGestureRecognizer];
    [doubleTapGestureRecognizer release];
    
}
- (void)drawRect:(CGRect)rect 
{
    if (_textFrame) {
        @autoreleasepool {
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGAffineTransform flipVertical = CGAffineTransformMake(1,0,0,-1,0,_adjustSize.height);
            CGContextConcatCTM(context, flipVertical);
            CGContextSetTextDrawingMode(context, kCGTextFill);
            
            // 获取CTFrame中的CTLine
            CFArrayRef lines = CTFrameGetLines(_textFrame);
            CGPoint origins[CFArrayGetCount(lines)];
            CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, 0), origins);
            
            for (int i = 0; i < CFArrayGetCount(lines); i++) {
                // 获取CTLine中的CTRun
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                CFArrayRef runs = CTLineGetGlyphRuns(line);
                
                CGFloat tmpX = origins[i].x + _edgeInsets.left;
                CGFloat tmpY = origins[i].y - _edgeInsets.top;
                
                if (_adjustSize.height - tmpY > rect.size.height) {
                    //文字的调度不能大于控件的调度
                    return;
                }
                for (int j = 0; j < CFArrayGetCount(runs); j++) {
                    CTRunRef run = CFArrayGetValueAtIndex(runs, j);
                    
                    CGContextSetTextPosition(context,tmpX, tmpY);
                    
                    
                    
                    // 获取CTRun的属性
                    NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
                    NSNumber *num = [attDic objectForKey:kXXCustomGlyphAttributeType];
                    if (num) {
                        // 不管是绘制链接还是表情，我们都需要知道绘制区域的大小，所以我们需要计算下
                        
                        int type = [num intValue];
                        if (type == XXCustomGlyphAttributeURL) {// 如果是绘制链接
                            
                            // 绘制文字
                            CTRunDraw(run, context, CFRangeMake(0, 0));
                        }
                        else if (type == XXCustomGlyphAttributeImage) {// 如果是绘制表情
                            // 表情区域是不需要文字的，所以我们只进行图片的绘制
                            
                            //获取一行中上行高(ascent)，下行高(descent)，行距(leading),整行高为(ascent+|descent|+leading) 返回值为整行字符串长度占有的像素宽度。
                            CGRect runBounds;
                            CGFloat ascent;
                            CGFloat descent;
                            CGFloat leading;
                            
                            CTRunGetTypographicBounds(run,
                                                      CFRangeMake(0, 0),
                                                      &ascent,
                                                      &descent,
                                                      &leading);
                            //设置宽和高
                            runBounds.size.height = ascent - descent*2;
                            runBounds.size.width = ascent - descent*2;
                            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringIndicesPtr(run)[0], NULL);
                            runBounds.origin.x = tmpX + xOffset + descent;
                            runBounds.origin.y = tmpY - descent*2;
                            
                            NSString *imageName = [attDic objectForKey:kXXCustomGlyphAttributeImageName];
                            UIImage *image = [UIImage imageNamed:imageName];
                            CGContextDrawImage(context, runBounds, image.CGImage);
                        }
                        
                    }
                    else {// 没有特殊处理的时候我们只进行文字的绘制
                        CTRunDraw(run, context, CFRangeMake(0, 0));
                    }
                }
            }
        }
    }
}

//在指定位置添加一个图片
- (void)replaceImageName:(NSString *)imageName atIndex:(NSInteger)loc
{
    [_htmlString replaceImageName:imageName atIndex:loc];
    [_attributedString setAttributedString:_htmlString.attributedString];
    [self updateFrameWithAttributedString];
    [self setNeedsDisplay];
}
- (void)setHtmlText:(NSString *)htmlText
{
    if (_htmlText != htmlText) {
        if (_htmlText) {
            [_htmlText release];
            _htmlText = nil;
        }
        _htmlText = [htmlText copy];
        //赋值
        _htmlString.font = self.font;
        _htmlString.textColor = self.textColor;
        _htmlString.analyseLink = self.analyseLink;
        _htmlString.analyseHref = self.analyseHref;
        [_htmlString transformText:htmlText];
        //设置一下
        [_attributedString setAttributedString:_htmlString.attributedString];
        [self updateFrameWithAttributedString];
        [self setNeedsDisplay];
    }
}
- (void)setHtmlString:(XXHtmlString *)htmlString
{
    if (_htmlString != htmlString) {
        if (_htmlString) {
            [_htmlString release];
            _htmlString = nil;
        }
        _htmlString = [htmlString mutableCopy];
        //设置一下
        [_attributedString setAttributedString:_htmlString.attributedString];
        //赋值
        [self updateFrameWithAttributedString];
        [self setNeedsDisplay];
    }
}

- (void)updateFrameWithAttributedString 
{
    if (_textFrame) {
        CFRelease(_textFrame),
        _textFrame = NULL;
    }
    CFMutableAttributedStringRef string = (__bridge CFMutableAttributedStringRef)_attributedString;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(string);
    CGMutablePathRef path = CGPathCreateMutable();
    CFRange fitCFRange = CFRangeMake(0,0);
    CGSize maxSize = CGSizeMake(self.frame.size.width - _edgeInsets.left - _edgeInsets.right, CGFLOAT_MAX);
    
    CGSize sz = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRangeMake(0,0),NULL,maxSize,&fitCFRange);
    _adjustSize = sz;
    
    CGRect rect = (CGRect){CGPointZero, sz};
    CGPathAddRect(path, NULL, rect);
    
    _textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    
    CGPathRelease(path);
    CFRelease(framesetter);
}


//点击了一下
-(void)tap:(UITapGestureRecognizer *)sender
{
    //NSLog(@"开始点击");
    
    _isClickLink = FALSE;
    
    CGPoint location = [sender locationInView:self];
    location.x -= _edgeInsets.left;
    location.y -= _edgeInsets.top;
    
    //获取点击位置所处的字符位置，就是相当于点击了第几个字符
    CFIndex index = [self characterIndexAtPoint:location];
    
    if (index) {
        //判断点击的字符是否在需要处理点击事件的字符串范围内，这里是hard code了需要触发事件的字符串范围
        //从_markupParser读取所有连接地址的起始点比较
        
        for (NSString *key in _htmlString.links.allKeys) {
            NSRange range = NSRangeFromString(key);
            if (index >= range.location && index <= range.location + range.length) {
                //如果在点击区域,触发超连接
                _linkUrl = [_htmlString.links objectForKey:key];
                
                _isClickLink = TRUE;
                
                _linkRange = range;
                
            }
        }
    }
    
    if (_isClickLink) {
        //NSLog(@"点击超链接");
        //设置超连接的颜色为XFHtmlLabelLinkClickColor
        [self setTextColorAtRange:_linkRange withColor:kColorLinkHighlighted withFont:[UIFont systemFontOfSize:self.font.pointSize]];
    }else{
        //如果没有点击超链接,就是点中了背景
        if (_canTap) {
            [self setBackgroundColor];
        }
    }
    //0.1后取消点击的效果
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(canceTap:) userInfo:sender repeats:NO];
}
//
- (void)canceTap:(UITapGestureRecognizer *)sender
{
    //触发事件
    if (_isClickLink) {
        //还原超链接颜色
        [self setTextColorAtRange:_linkRange withColor:kColorLink withFont:[UIFont systemFontOfSize:self.font.pointSize]];
        //触发代理
        if(_delegate && [_delegate respondsToSelector:@selector(htmlView:withURL:)])
        {
            _linkUrl = [_linkUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [_delegate htmlView:self withURL:_linkUrl];
        }
    }
    else{
        if (_canTap) {
            //点击后将颜色还原
            [self cancelBackgroundColor];
        }
        if(_delegate && [_delegate respondsToSelector:@selector(htmlView:tap:)])
        {
            [_delegate htmlView:self tap:sender];
        }
    }
}
//触发长按
-(void)longPress:(UILongPressGestureRecognizer *)recognizer {
    
    
    if(_delegate && [_delegate respondsToSelector:@selector(htmlView:longPress:)])
    {
        [_delegate htmlView:self longPress:recognizer];
    }
    
    if (_openCopy) {
        //复制功能
        
        switch (recognizer.state) {
            case UIGestureRecognizerStateBegan:
                
                [self setBackgroundColor];
                
                UIMenuItem *itCopy = [[UIMenuItem alloc] initWithTitle:@"复制" action:_copyAction];
                
                UIMenuController *menu = [UIMenuController sharedMenuController];
                if (_textCopy) {
                    //赞使用指定文字
                    menu.accessibilityLabel = _textCopy;
                }
                else{
                    menu.accessibilityLabel = _htmlText;
                }
                [menu setMenuItems:[NSArray arrayWithObjects:itCopy,  nil]];
                [menu setTargetRect:self.frame inView:self.superview];
                [menu setMenuVisible:YES animated:YES];
                
                //释放
                [itCopy release];
                
                //监听菜单消失
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(menuWillHide:)
                                                             name:UIMenuControllerWillHideMenuNotification
                                                           object:nil];
                
                break;
            case UIGestureRecognizerStateEnded:
                
                break;
            case UIGestureRecognizerStateCancelled:
                
                break;
                
            default:
                break;
        }
        
    }
    else{
        switch (recognizer.state) {
            case UIGestureRecognizerStateBegan:
                [self setBackgroundColor];
                break;
            case UIGestureRecognizerStateEnded:
                [self cancelBackgroundColor];
                
                break;
            case UIGestureRecognizerStateCancelled:
                [self cancelBackgroundColor];
                
                break;
                
            default:
                break;
        }
    }
}

//菜单隐藏了
- (void)menuWillHide:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelBackgroundColor];
}









//双击
- (void)doubleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    if(_delegate && [_delegate respondsToSelector:@selector(htmlView:doubleTap:)])
    {
        [_delegate htmlView:self doubleTap:gestureRecognizer];
    }
}
//设置背景颜色
- (void)setBackgroundColor
{
    if (_backgroundColorHighlighted)
        //修改背景色
        self.backgroundColor = _backgroundColorHighlighted;
}
//还原背景颜色
- (void)cancelBackgroundColor
{
    if (_backgroundColorNormal) {
        self.backgroundColor = _backgroundColorNormal;
    }
}












//修改文字的颜色,用于超连接
- (void)setTextColorAtRange:(NSRange )range withColor:(UIColor *)color withFont:(UIFont *)font
{
    //文字属性添加
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)color.CGColor, kCTForegroundColorAttributeName,
                           (id)fontRef, kCTFontAttributeName,
                           nil];
    
    
    [_attributedString setAttributes:attrs range:range];
    
    
    CFRelease(fontRef);
    [self setNeedsDisplay];
}


//计算出点击的文字是第几个
- (CFIndex)characterIndexAtPoint:(CGPoint)location {
    
    //获取每一行
    CFArrayRef lines = CTFrameGetLines(_textFrame);
    CGPoint origins[CFArrayGetCount(lines)];
    
    //获取每行的原点坐标
    CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, 0), origins);
    CTLineRef line = NULL;
    CGPoint lineOrigin = CGPointZero;
    for (int i= 0; i < CFArrayGetCount(lines); i++)
    {
        CGPoint origin = origins[i];
        //坐标转换，把每行的原点坐标转换为uiview的坐标体系.有3像素的空白
        CGFloat y = _adjustSize.height - origin.y + 3;
        
        //判断点击的位置处于那一行范围内
        if ((location.y <= y) && (location.x >= origin.x))
        {
            line = CFArrayGetValueAtIndex(lines, i);
            lineOrigin = origin;
            break;
        }
    }
    
    location.x -= lineOrigin.x;
    
    //获取点击位置所处的字符位置，就是相当于点击了第几个字符
    CFIndex index = CTLineGetStringIndexForPosition(line, location);
    //NSLog(@"index:%ld",index);
    return index;
}
//自动适应大小
- (void)sizeToHtmlFit
{
    CGRect rect = self.frame;
    
    rect.size.height    = _adjustSize.height + _edgeInsets.top + _edgeInsets.bottom;
    rect.size.width     = _adjustSize.width + _edgeInsets.left + _edgeInsets.right;
    
    self.frame = rect;
}

//宽度不能小于minWidth
- (void)sizeToHtmlFitWithMinWith:(CGFloat)minWidth
{
    CGRect rect = self.frame;
    
    rect.size.height    = _adjustSize.height + _edgeInsets.top + _edgeInsets.bottom;
    rect.size.width     = _adjustSize.width + _edgeInsets.left + _edgeInsets.right;
    
    if (rect.size.width < minWidth) {
        rect.size.width = minWidth;
    }
    self.frame = rect;
}

- (void)dealloc
{
    if (_textFrame) {
        CFRelease(_textFrame),
        _textFrame = NULL;
    }
    if (_font) {
        [_font release];
        _font = nil;
    }
    if (_textCopy) {
        [_textCopy release];
        _textCopy = nil;
    }
    if (_htmlText) {
        [_htmlText release];
        _htmlText = nil;
    }
    if (_htmlString) {
        [_htmlString release];
        _htmlString = nil;
    }
    if (_attributedString) {
        [_attributedString release];
        _attributedString = nil;
    }
    if (_backgroundColorNormal) {
        [_backgroundColorNormal release];
        _backgroundColorNormal = nil;
    }
    if (_backgroundColorHighlighted) {
        [_backgroundColorHighlighted release];
        _backgroundColorHighlighted = nil;
    }
    [super dealloc];
    
}
@end
