//
//  NSString+Weibo.m
//  CoreTextDemo
//
//  Created by cxjwin on 13-10-31.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

NSString *const kXXCustomGlyphAttributeType = @"CustomGlyphAttributeType";
NSString *const kXXCustomGlyphAttributeRange = @"CustomGlyphAttributeRange";
NSString *const kXXCustomGlyphAttributeImageName = @"CustomGlyphAttributeImageName";
NSString *const kXXCustomGlyphAttributeInfo = @"CustomGlyphAttributeInfo";

#import "XXHtmlString.h"


/* Callbacks */
static void deallocCallback(void *refCon){
    free(refCon), refCon = NULL;
}

static CGFloat ascentCallback(void *refCon){
    XXCustomGlyphMetricsRef metrics = (XXCustomGlyphMetricsRef)refCon;
    return metrics->ascent;
}

static CGFloat descentCallback(void *refCon){
    XXCustomGlyphMetricsRef metrics = (XXCustomGlyphMetricsRef)refCon;
    return metrics->descent;
}

static CGFloat widthCallback(void *refCon){
    XXCustomGlyphMetricsRef metrics = (XXCustomGlyphMetricsRef)refCon;
    return metrics->width;
}



@implementation XXHtmlString

- (id)init
{
    self = [super init];
    if (self) {
        _links = [[NSMutableDictionary alloc] init];
        _analyseHref = YES;
        _analyseLink = YES;
        _lineBreak = kCTLineBreakByCharWrapping;
    }
    return self;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
    XXHtmlString *newItem = [[XXHtmlString allocWithZone:zone] init];
    
    newItem.links = [self.links mutableCopy];
    newItem.string = self.string;
    newItem.attributedString = [self.attributedString mutableCopy];
    return newItem;
    
}
//解析文字
- (void)transformText:(NSString *)text
{
    if (!text) {
        return;
    }
    if (_string) {
        [_string release];
        _string = nil;
    }
    if (_attributedString) {
        [_attributedString release];
        _attributedString = nil;
    }
    _string = [text copy];
    
    //初始化
    _attributedString = [[NSMutableAttributedString alloc] init];
    
    [_attributedString beginEditing];
    
    // 匹配emoji
    NSString *regex_emoji = @"\\[(.*?)\\]";
    NSRegularExpression *exp_emoji = 
    [[NSRegularExpression alloc] initWithPattern:regex_emoji
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           error:nil];
    NSArray *emojis = [exp_emoji matchesInString:text
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           range:NSMakeRange(0, [text length])];
    NSUInteger location = 0;
    for (NSTextCheckingResult *result in emojis) {
        NSRange range = result.range;
        
        //将中间的文字加入
        NSString *subStr = [text substringWithRange:NSMakeRange(location, range.location - location)];
        NSMutableAttributedString *attSubStr = [[[NSMutableAttributedString alloc] initWithString:subStr] autorelease];
        [_attributedString appendAttributedString:attSubStr];
        
        location = range.location + range.length;
        
        NSString *emojiKey = [text substringWithRange:range];
        emojiKey = [emojiKey substringWithRange:NSMakeRange(1, emojiKey.length - 2)];
        NSString *imageName = [kSymbolExpressionValueToKey objectForKey:emojiKey];
        if (imageName) {
            //添加图片
            [self appendImageName:imageName];
        }
        else {
            //没有查到图片,请将文字加入
            NSString *rSubStr = [text substringWithRange:range];
            NSMutableAttributedString *originalStr = [[[NSMutableAttributedString alloc] initWithString:rSubStr] autorelease];
            [_attributedString appendAttributedString:originalStr];
        }
    }
    //加入剩余的内容
    if (location < [text length]) {
        NSRange range = NSMakeRange(location, [text length] - location);
        NSString *subStr = [text substringWithRange:range];
        
        [self appendString:subStr withRange:range];
        
    }
    if (_analyseHref) {
        //匹配href http://addfriend.xuexin.org.cn
        
        NSString *__newStr = [_attributedString string];
        
        NSString *regex_http = @"<a href=\"http://(addfriend|friendinfo).xuexin.org.cn/(.*?)\"(.*?)>.*?</a>";
        
        NSRegularExpression *exp_http = [NSRegularExpression regularExpressionWithPattern:regex_http
                                                                                  options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                                                                    error:nil];
        
        NSArray *https = [exp_http matchesInString:__newStr
                                           options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                             range:NSMakeRange(0, [__newStr length])];
        
        //删除现在文字后,整个字符串会减少
        NSInteger rangeChange = 0;
        for (NSTextCheckingResult *result in https) {
            //超连接
            NSRange _range = [result range];
            _range.location -= rangeChange;
            
            NSString *url = [__newStr substringWithRange:_range];
            //删除现有文字
            [_attributedString deleteCharactersInRange:_range];
            
            //读取标题
            NSString *title = [self deleteHTML:url];
            //读取连接地址
            NSString *href = [self getHref:url];
            
            //计算新的位置
            //生成新rang
            

            NSRange tmpRange = NSMakeRange(_range.location, title.length);
            rangeChange += _range.length - title.length;//计算位移
            [self insertHref:href withTitle:title withRange:tmpRange];
        }
    }
    if (_analyseLink) {
        //支持超链接
        //匹配超链
        NSString *__newStr = [_attributedString string];
        
        NSRegularExpression *exp_http = [NSRegularExpression regularExpressionWithPattern:kRegex_http
                                                                                  options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                                                                    error:nil];
        NSArray *https = [exp_http matchesInString:__newStr
                                           options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                             range:NSMakeRange(0, [__newStr length])];
        
        for (NSTextCheckingResult *result in https) {
            //超连接
            NSRange _range = [result range];
            //添加到数组中
            NSString *url = [__newStr substringWithRange:_range];
            [_links setObject:url forKey:NSStringFromRange(_range)];
            
            // 设置自定义属性，绘制的时候需要用到
            NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   (id)kColorLink.CGColor, kCTForegroundColorAttributeName,
                                   [NSNumber numberWithInt:XXCustomGlyphAttributeURL], kXXCustomGlyphAttributeType,
                                   nil];
            
            [_attributedString addAttributes:attrs range:_range];
        }
    }
    
    //添加属性

    //换行模式，设置段落属性
    CTParagraphStyleSetting lineBreakMode;
    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakMode.value = &_lineBreak;
    lineBreakMode.valueSize = sizeof(CTLineBreakMode);
    
    //创建文本行间距
    CGFloat linesSpacing = 3.0f;
    CTParagraphStyleSetting lineSpaceStyle;
    lineSpaceStyle.spec = kCTParagraphStyleSpecifierLineSpacing;
    lineSpaceStyle.valueSize = sizeof(CGFloat);
    lineSpaceStyle.value = &linesSpacing;
    
    CTParagraphStyleSetting settings[] = {
        lineBreakMode,lineSpaceStyle
    };
    CTParagraphStyleRef style = CTParagraphStyleCreate(settings, 2);
    
    //字体大小
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)_font.fontName, _font.pointSize, NULL);
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)style, kCTParagraphStyleAttributeName,
                           (id)fontRef, kCTFontAttributeName,
                           nil];
    
    
    [_attributedString addAttributes:attrs range:NSMakeRange(0, [_attributedString length])];
    
    CFRelease(style);
    
    [_attributedString endEditing];
}

//添加一个图片
- (void)appendImageName:(NSString *)imageName
{
    //将空格替换成OxFFFC,这样才能正确的将末尾空格解析出来
    unichar objectReplacementChar = 0xFFFC;
    NSString * objectReplacementString = [NSString stringWithCharacters:&objectReplacementChar length:1];
    
    NSMutableAttributedString *replaceStr = [[[NSMutableAttributedString alloc] initWithString:objectReplacementString] autorelease];
    NSRange __range = NSMakeRange([_attributedString length], 1);
    [_attributedString appendAttributedString:replaceStr];
    
    [self addImageName:imageName withRange:__range];
}

//在指定位置添加一个图片
- (void)replaceImageName:(NSString *)imageName atIndex:(NSInteger)loc
{
    // 这里不用空格，空格有个问题就是连续空格的时候只显示在一行
    unichar objectReplacementChar = 0xFFFC;
    NSString * objectReplacementString = [NSString stringWithCharacters:&objectReplacementChar length:1];
    
    NSMutableAttributedString *replaceStr = [[[NSMutableAttributedString alloc] initWithString:objectReplacementString] autorelease];
    NSRange __range = NSMakeRange(loc, 1);
    [_attributedString replaceCharactersInRange:__range withAttributedString:replaceStr];
    
    [self addImageName:imageName withRange:__range];
}
//添加图片
- (void)addImageName:(NSString *)imageName withRange:(NSRange)__range
{
    // 定义回调函数
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.getAscent = ascentCallback;
    callbacks.getDescent = descentCallback;
    callbacks.getWidth = widthCallback;
    callbacks.dealloc = deallocCallback;
    
    //获取一行中上行高(ascent)，下行高(descent)，行距(leading),整行高为(ascent+|descent|+leading) 返回值为整行字符串长度占有的像素宽度。
    XXCustomGlyphMetricsRef metrics = malloc(sizeof(XXCustomGlyphMetrics));
    metrics->ascent = _font.pointSize+1;
    metrics->descent = 1;
    metrics->width = _font.pointSize+1;
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, metrics);
    [_attributedString addAttribute:(NSString *)kCTRunDelegateAttributeName
                              value:(__bridge id)delegate
                              range:__range];
    CFRelease(delegate);
    
    // 设置自定义属性，绘制的时候需要用到
    [_attributedString addAttribute:kXXCustomGlyphAttributeType
                              value:[NSNumber numberWithInt:XXCustomGlyphAttributeImage]
                              range:__range];
    [_attributedString addAttribute:kXXCustomGlyphAttributeImageName
                              value:imageName
                              range:__range];
    
}
//插入href超链接
- (void)insertHref:(NSString *)link
         withTitle:(NSString *)title
         withRange:(NSRange)range
{
    if (!link) {
        NSLog(@"link为空");
        return;
    }
    [_links setObject:link forKey:NSStringFromRange(range)];
    // 设置自定义属性，绘制的时候需要用到
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)kColorLink.CGColor, kCTForegroundColorAttributeName,
                           [NSNumber numberWithInt:XXCustomGlyphAttributeURL], kXXCustomGlyphAttributeType,
                           nil];
    
    NSMutableAttributedString *originalStr = [[[NSMutableAttributedString alloc] initWithString:title] autorelease];
    [originalStr addAttributes:attrs range:NSMakeRange(0, title.length)];
    
    [_attributedString insertAttributedString:originalStr atIndex:range.location];
}


//添加纯文字
- (void)appendString:(NSString *)subStr
           withRange:(NSRange)range
{
    //将空格替换成OxFFFC,这样才能正确的将末尾空格解析出来
//    unichar objectReplacementChar = 0xFFFC;
//    NSString * objectReplacementString = [NSString stringWithCharacters:&objectReplacementChar length:1];
//    subStr = [subStr stringByReplacingOccurrencesOfString:@" " withString:objectReplacementString];
    
    NSMutableAttributedString *attSubStr = [[[NSMutableAttributedString alloc] initWithString:subStr] autorelease];
    
    // 设置自定义属性，绘制的时候需要用到
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)_textColor.CGColor, kCTForegroundColorAttributeName,
                           nil];
    [attSubStr addAttributes:attrs range:NSMakeRange(0, subStr.length)];
    
    [_attributedString appendAttributedString:attSubStr];
}


//提取href
- (NSString *)getHref:(NSString *)html {
    
    
    NSRegularExpression *exp_http = [NSRegularExpression regularExpressionWithPattern:kRegex_http
                                                                              options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                                                                error:nil];
    
    NSArray *https = [exp_http matchesInString:html
                                       options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                         range:NSMakeRange(0, [html length])];
    
    for (NSTextCheckingResult *result in https) {
        //超连接
        NSRange _range = [result range];
        //添加到数组中
        NSString *url = [html substringWithRange:_range];
        return url;
    }
    return nil;
}





//删除所有html标签
- (NSString *)deleteHTML:(NSString *)html {
    if (!html) {
        return html;
    }
    NSScanner *theScanner;
    NSString *text = nil;
    
    theScanner = [NSScanner scannerWithString:html];
    
    while ([theScanner isAtEnd] == NO) {
        
        // find start of tag
        [theScanner scanUpToString:@"<" intoString:NULL] ;
        
        // find end of tag
        [theScanner scanUpToString:@">" intoString:&text] ;
        
        // replace the found tag with a space
        //(you can filter multi-spaces out later if you wish)
        html = [html stringByReplacingOccurrencesOfString:
                [ NSString stringWithFormat:@"%@>", text]
                                               withString:@""];
        
    } // while //
    
    return html;
}












//读取文字的高度
+ (CGSize)sizeWithString:(NSString *)string
            withMaxWidth:(CGFloat)maxWidth
                withFont:(UIFont *)font
{
    if (!string)
        return CGSizeZero;
    
    XXHtmlString *htmlString = [[[XXHtmlString alloc] init] autorelease];
    htmlString.font = font;
    htmlString.analyseLink = NO;
    [htmlString transformText:string];
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)htmlString.attributedString);
    CFRange fitCFRange = CFRangeMake(0,0);
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
    CGSize sz = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRangeMake(0,0),NULL,maxSize,&fitCFRange);
    return sz;
}


//读取文字的高度
+ (CGSize)sizeWithString:(NSAttributedString *)attributedString
            withMaxWidth:(CGFloat)maxWidth
{
    if (!attributedString)
        return CGSizeZero;
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)attributedString);
    CFRange fitCFRange = CFRangeMake(0,0);
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
    CGSize sz = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRangeMake(0,0),NULL,maxSize,&fitCFRange);
    return sz;
}

- (void)dealloc
{
    if (_links) {
        [_links release];
        _links = NULL;
    }
    if (_string) {
        [_string release];
        _string = nil;
    }
    if (_attributedString) {
        [_attributedString release];
        _attributedString = nil;
    }
    if (_font) {
        [_font release];
        _font = nil;
    }
    if (_textColor) {
        [_textColor release];
        _textColor = nil;
    }
    [super dealloc];
    
}
@end
