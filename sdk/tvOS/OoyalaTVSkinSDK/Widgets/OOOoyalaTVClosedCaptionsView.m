#import <OOOoyalaTVClosedCaptionsView.h>
#import <OoyalaSDK/OOCaption.h>
#import <OoyalaSDK/OOClosedCaptionsStyle.h>
#import <OOOoyalaTVClosedCaptionsLabel.h>
#import <CoreText/CoreText.h>
static CGFloat arbitraryScalingFactor = 1.2;


@interface OOClosedCaptionsTextBackgroundView : UIView
@property (nonatomic, strong) NSArray* textRects;
@property (nonatomic, strong) UIColor *highlightColor;
@property (nonatomic) CGFloat highlightOpacity;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic) CGFloat shadowOpacity;
@end

@implementation OOClosedCaptionsTextBackgroundView


-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.shadowOffset = CGSizeMake(0, 0);
        self.shadowOpacity = 0;
        self.highlightColor = [UIColor clearColor];
        self.highlightOpacity = 0;
    }
    return self;
}


-(void)updateBackground {
    [self setNeedsDisplay];
}

@end


@interface OOClosedCaptionsTextView : UITextView
@property (nonatomic, strong) NSString* nextText;
@property (nonatomic) MACaptionAppearanceTextEdgeStyle edgeStyle;
@property (nonatomic) CGFloat textSize;
@property (nonatomic, strong) OOClosedCaptionsTextBackgroundView* backgroundView;
@property (nonatomic, strong) NSMutableArray* resultLines;
@property (nonatomic, strong) OOClosedCaptionsStyle* style;
@end

@implementation OOClosedCaptionsTextView

-(id) initWithFrame:(CGRect)frame style:(OOClosedCaptionsStyle*) style backgroundView:(OOClosedCaptionsTextBackgroundView*) backgroundView{
    self = [super initWithFrame:frame];
    
    // Disable scroll and set the content off to be zero so that when the container will not
    //  scroll if we have some text out of the window.
    [self setContentOffset:CGPointZero animated:NO];
    [self setScrollEnabled:NO];
    
    self.style = style;
    self.backgroundView = backgroundView;
    
    [self setFont:style.textFontName frame:frame baseFontSize:style.textSize];
    
    [self setTextColor:style.textColor];
    
    self.alpha = style.textOpacity;
    self.textSize = style.textSize;
    //self.editable = NO;
    self.userInteractionEnabled = NO;
    // This is important!!!! make sure shadow can be shown
    self.backgroundColor = [UIColor clearColor];
    if (style.presentation != OOClosedCaptionPaintOn) {
        self.textAlignment = NSTextAlignmentCenter;
    }
    if (&MACaptionAppearanceCopyForegroundColor) {
        // Settings for text edge style
        if (style.edgeStyle == kMACaptionAppearanceTextEdgeStyleUniform) {
            self.edgeStyle = kMACaptionAppearanceTextEdgeStyleUniform;
        } else if (style.edgeStyle != kMACaptionAppearanceTextEdgeStyleNone && style.edgeStyle != kMACaptionAppearanceTextEdgeStyleUndefined) {
            self.layer.shadowColor = [[UIColor blackColor] CGColor];
            self.layer.shadowOpacity = 1.0f;
            self.layer.shadowRadius = 1.0f;
            if (style.edgeStyle == kMACaptionAppearanceTextEdgeStyleDropShadow) {
                self.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
                backgroundView.shadowOffset = CGSizeMake(0.0f, 0.0f);
                backgroundView.shadowOpacity = 0.8;
            } else if (style.edgeStyle == kMACaptionAppearanceTextEdgeStyleDepressed) {
                self.layer.shadowOffset = CGSizeMake(4.0f, -4.0f);
                backgroundView.shadowOffset = CGSizeMake(4.0f, -4.0f);
                backgroundView.shadowOpacity = 0.8;
            } else if (style.edgeStyle == kMACaptionAppearanceTextEdgeStyleRaised) {
                self.layer.shadowOffset = CGSizeMake(-4.0f, 4.0f);
                backgroundView.shadowOffset = CGSizeMake(-4.0f, 4.0f);
                backgroundView.shadowOpacity = 0.8;
            }
        }
    }
    return self;
}

/**
 * Add scaling based on video view size when compared to portrait width
 * Captions show up with "default" size when the width of the player is the portrait width
 * When the width of the player is larger or smaller, we will scale the captions accordingly
 */
-(void) setFont:(NSString *)fontName frame:(CGRect)frame baseFontSize:(CGFloat)fontSize {
    CGSize mainBoundsSize = [UIScreen mainScreen].bounds.size;
    CGFloat portraitWidth = mainBoundsSize.width > mainBoundsSize.height ? mainBoundsSize.height : mainBoundsSize.width;
    CGFloat scalingFactor = frame.size.width / portraitWidth;
    [self setFont:[UIFont fontWithName:fontName size:fontSize * scalingFactor*arbitraryScalingFactor]];
}

-(void) setText:(NSString *)text {
    // Make sure each text are split correctly before adding to UITextView
    self.nextText = text;
    
    if (&MACaptionAppearanceCopyForegroundColor && self.edgeStyle == kMACaptionAppearanceTextEdgeStyleUniform) {
        [self setNeedsDisplay];
    }
    [super setText:text];
}

-(NSArray*)getRectsForEachLine:(NSArray*)separatedLines {
    NSMutableArray* textRects = [[NSMutableArray alloc] init];
    UITextPosition *beginning = self.beginningOfDocument;
    NSUInteger startPostition = 0;
    for (NSString* line in separatedLines) {
        NSRange range = NSMakeRange(startPostition, line.length);
        UITextPosition *start = [self positionFromPosition:beginning offset:(NSInteger)range.location];
        UITextPosition *end = [self positionFromPosition:start offset:(NSInteger)range.length];
        UITextRange *textRange = [self textRangeFromPosition:start toPosition:end];
        CGRect textRect = [self firstRectForRange:textRange];
        
        // The +0.5 in textRect.origin.y is for match the outline better with text. maybe changed with font size
        CGRect newTextRect = CGRectMake(textRect.origin.x, textRect.origin.y + 1.5, textRect.size.width, textRect.size.height);
        [textRects addObject:[NSValue valueWithCGRect:newTextRect]];
        startPostition += line.length + 1;
    }
    return [textRects copy];
}
@end


@interface OOOoyalaTVClosedCaptionsView()
@property (nonatomic, strong) OOClosedCaptionsTextView* textView;
@property (nonatomic, strong) OOClosedCaptionsTextBackgroundView* backgroundView;
@property (nonatomic, strong) NSString* splitText;
@property (nonatomic) CGFloat textViewEdge; // The space between bottom of textview and bottom of the parent view
@property (nonatomic, strong) NSString* currentText;
@property (nonatomic) BOOL stopPainting;
@end

@implementation OOOoyalaTVClosedCaptionsView

+ (void) setArbitararyScalingFactor:(CGFloat)scalingFactor {
    arbitraryScalingFactor = scalingFactor;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setContentMode:UIViewContentModeScaleAspectFill];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    self.textViewEdge = 10;
    return self;
}

- (void)setClosedCaption:(OOCaption *)caption {
    self.caption = caption;
    [self setNeedsDisplay];
}

- (void)setCaptionStyle:(OOClosedCaptionsStyle *)style {
    self.style = style;
    for (UIView *subview in self.textView.subviews) {
        [subview removeFromSuperview];
    }
    [self.textView removeFromSuperview];
    self.textView = nil;
    
    if (self.backgroundView != nil) {
        self.backgroundView.hidden = YES;
        [self.backgroundView removeFromSuperview];
        self.backgroundView = nil;
    }
    
    CGFloat height = self.style.textSize * 6;
    CGRect frame = CGRectMake(.1 * self.bounds.size.width, self.frame.size.height - height - self.textViewEdge, .8 * self.bounds.size.width, height);
    // When showing shadow in UITextView the background of UITextView itself has to have clearColor.
    // Add this backgroundView as real background
    self.backgroundView = [[OOClosedCaptionsTextBackgroundView alloc] initWithFrame:frame];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    
    // For classic style setting in device we should take style.backgroundOpacity
    // For other settings we should take style.windowOpacity
    // This could be a problem of
    self.backgroundView.backgroundColor = self.style.windowColor;
    self.backgroundView.highlightOpacity = self.style.backgroundOpacity;
    self.backgroundView.highlightColor = self.style.backgroundColor;
    
    self.backgroundView.alpha = fmax(self.style.backgroundOpacity, self.style.windowOpacity);
    
    self.backgroundView.hidden = YES;
    self.backgroundView.layer.cornerRadius = 10;
    self.backgroundView.layer.masksToBounds = YES;
    
    // setup UITextView according to style
    self.textView = [[OOClosedCaptionsTextView alloc] initWithFrame:frame style:style backgroundView:self.backgroundView];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    
    [self addSubview:self.backgroundView];
    [self addSubview:self.textView];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    //do not draw if no text
    if (self.caption.text == nil) {
        self.textView.hidden = YES;
        self.backgroundView.hidden = YES;
        return;
    }
    
    if (self.textView.hidden || self.backgroundView.hidden) {
        self.textView.hidden = NO;
        self.backgroundView.hidden = NO;
    }
    
    [self matchFrameWithText];
    
    // update highlight
    self.backgroundView.textRects = [self.textView getRectsForEachLine:[self.splitText componentsSeparatedByString:@"\n"]];
    [self.backgroundView updateBackground];
}

// Set UITextView frame based on current closed caption text size
// This is for both pop-on and paint-on
- (void)matchFrameWithText {
    
    // Set maxWidth based on the self.frame (the passed frame in init function is the frame of player)
    CGFloat maxWidth = 0.0;
    maxWidth = self.frame.size.width * 0.9;
    
    
    [self.textView setFont:self.style.textFontName frame:self.frame  baseFontSize:self.style.textSize];
    
    // Find the longest line in current closed caption
    NSArray* lines = [self.caption.text componentsSeparatedByString:@"\n"];
    CGSize maxLineSize = CGSizeMake(0, 0);
    for (NSString* line in lines) {
        CGSize size = [line sizeWithAttributes:@{NSFontAttributeName: self.textView.font}];
        if (size.width > maxLineSize.width) {
            maxLineSize = size;
            if (maxLineSize.width > maxWidth) {
                break;
            }
        }
    }
    
    CGFloat frameWidth = maxWidth;
    if (maxWidth > maxLineSize.width) {
        frameWidth = maxLineSize.width;
    }
    
    // Calculate height of the frame based on the width calculated above
    NSMutableString* resultText = [[NSMutableString alloc] init];
    NSInteger lineCount = (NSInteger)[lines count];
    
    // Need to split some lines if those lines are longer than the maxWidth
    if (maxLineSize.width >= maxWidth) {
        NSInteger currentLineNum = 0;
        for (NSString* line in lines) {
            currentLineNum++;
            NSMutableString* temp = [NSMutableString stringWithString:line];
            
            // Find the last whitespace before exceeding maxWidth and insert a new line char there to split that line
            NSUInteger prevWhitespaceIndex = 0;
            for (unsigned int i = 0; i < [line length]; i++) {
                unichar currentChar = [line characterAtIndex:i];
                CGSize subStringSize = [[line substringToIndex:i] sizeWithAttributes:@{NSFontAttributeName: self.textView.font}];
                if (subStringSize.width > frameWidth) {
                    // Insert a newline char in previous index of whitespace to split current line into two lines
                    [temp insertString:@"\n" atIndex:prevWhitespaceIndex];
                    lineCount++;
                    break;
                }
                if (currentChar == ' ') {
                    prevWhitespaceIndex = i;
                }
            }
            
            // Reconstruct a new closed caption text with split lines
            if (currentLineNum == (NSInteger)[lines count]) {
                if (temp != nil) {
                    [resultText appendString: temp];
                }
            } else {
                if ([NSString stringWithFormat: @"%@\n", temp] != nil) {
                    [resultText appendString: [NSString stringWithFormat: @"%@\n", temp]];
                }
            }
        }
    } else {
        if (self.caption.text != nil) {
            [resultText appendString: self.caption.text];
        }
    }
    // If the presentation is PaintOn then the text should be added one by one later in different threads.
    if (self.style.presentation != OOClosedCaptionPaintOn) {
        [self.textView setText:resultText];
    } else {
        [self.textView setText:@""]; // clean the layer before next text
    }
    
    frameWidth *= 1.1; // text padding
    frameWidth += 56; //needs more padding to display CC
    CGSize newSize = [self.textView sizeThatFits:CGSizeMake(frameWidth, MAXFLOAT)];
    CGRect newFrame = self.textView.frame;  
    
    CGFloat linePadding = 10;
    newFrame.size = CGSizeMake(fmaxf((float)newSize.width, (float)frameWidth), (maxLineSize.height + linePadding) * lineCount);
    
    CGFloat originalX = (self.frame.size.width - newFrame.size.width) / 2   ;
    self.textView.frame = CGRectMake(originalX, self.frame.size.height - newFrame.size.height - self.textViewEdge, frameWidth, (linePadding * 2 + maxLineSize.height * lineCount));
    
    if (self.style.presentation == OOClosedCaptionPopOn) {
        self.textView.textAlignment = NSTextAlignmentCenter;
    }
    self.backgroundView.frame = self.textView.frame;
    self.splitText = resultText;
}

@end
