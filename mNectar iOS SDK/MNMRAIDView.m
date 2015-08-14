#import "MNMRAIDView.h"

#define MN_IMG_CLOSE_NORMAL "MNMRAID.bundle/cancel"
#define MN_IMG_CLOSE_HIGHLIGHTED "MNMRAID.bundle/cancel_white"

@interface MNMRAIDView () <UIWebViewDelegate>

@end

@implementation MNMRAIDView

@synthesize placementType = _placementType;
@synthesize isViewable = _isViewable;
@synthesize expandWidth = _expandWidth;
@synthesize expandHeight = _expandHeight;
@synthesize useCustomClose = _useCustomClose;
@synthesize allowOrientationChange = _allowOrientationChange;
@synthesize forceOrientation = _forceOrientation;
@synthesize resizeWidth = _resizeWidth;
@synthesize resizeHeight = _resizeHeight;
@synthesize resizeOffsetX = _resizeOffsetX;
@synthesize resizeOffsetY = _resizeOffsetY;
@synthesize customClosePosition = _customClosePosition;
@synthesize allowOffscreen = _allowOffscreen;
@synthesize supportsInlineVideo = _supportsInlineVideo;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];

        _webView = [[UIWebView alloc] initWithFrame:frame];
        [[_webView scrollView] setScrollEnabled:NO];
        [_webView setBackgroundColor:[UIColor clearColor]];
        [_webView setOpaque:NO];
        [_webView setAllowsInlineMediaPlayback:YES];
        [_webView setMediaPlaybackRequiresUserAction:NO];
        [_webView setDelegate:self];
        [self addSubview:_webView];

        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_loadingIndicator setFrame:frame];
        [_loadingIndicator setHidden:YES];
        [self addSubview:_loadingIndicator];

        _closeImageNormal = [UIImage imageNamed:@MN_IMG_CLOSE_NORMAL];
        _closeImageHighlighted = [UIImage imageNamed:@MN_IMG_CLOSE_HIGHLIGHTED];

        _closeButton = [[UIButton alloc] initWithFrame:CGRectNull];
        [_closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeButton];

        CGRect screen = [[UIScreen mainScreen] bounds];

        [self inject:[[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MNMRAID.bundle/mraid.js" ofType:nil] encoding:NSUTF8StringEncoding error:nil]];
        [self setState:MNMRAIDStateLoading];
        [self setPlacementType:MNMRAIDPlacementTypeInline];
        [self setIsViewable:NO];
        [self setExpandWidth:screen.size.width];
        [self setExpandHeight:screen.size.height];
        [self setUseCustomClose:NO];
        [self setAllowOrientationChange:YES];
        [self setForceOrientation:MNMRAIDOrientationNone];
        [self setResizeWidth:frame.size.width];
        [self setResizeHeight:frame.size.height];
        [self setResizeOffsetX:0];
        [self setResizeOffsetY:0];
        [self setCustomClosePosition:MNMRAIDPositionTopRight];
        [self setAllowOffscreen:YES];
        [self setCurrentPosition:frame];
        [self setMaxSize:screen.size];
        [self setDefaultPosition:frame];
        [self setScreenSize:screen.size];
        [self setSupportsInlineVideo:YES];
    }

    return self;
}

- (NSString *)inject:(NSString *)js
{
    return [_webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)startLoading
{
    [_loadingIndicator startAnimating];
    [_loadingIndicator setHidden:NO];
}

- (void)stopLoading
{
    [_loadingIndicator setHidden:YES];
    [_loadingIndicator stopAnimating];
}

- (void)updateCloseButton
{
    CGRect frame = [self frame];
    CGRect closeButtonFrame = CGRectNull;

    switch ([self customClosePosition]) {
        case MNMRAIDPositionTopLeft:
            closeButtonFrame = CGRectMake(frame.origin.x, frame.origin.y, 50, 50);
            break;
        case MNMRAIDPositionTopRight:
            closeButtonFrame = CGRectMake(frame.origin.x + frame.size.width - 50, frame.origin.y, 50, 50);
            break;
        case MNMRAIDPositionBottomLeft:
            closeButtonFrame = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height - 50, 50, 50);
            break;
        case MNMRAIDPositionBottomRight:
            closeButtonFrame = CGRectMake(frame.origin.x + frame.size.width - 50, frame.origin.y + frame.size.height - 50, 50, 50);
            break;
        case MNMRAIDPositionTopCenter:
            closeButtonFrame = CGRectMake((frame.origin.x + frame.size.width) / 2.0, frame.origin.y, 50, 50);
            break;
        case MNMRAIDPositionBottomCenter:
            closeButtonFrame = CGRectMake((frame.origin.x + frame.size.width) / 2.0, frame.origin.y + frame.size.height - 50, 50, 50);
            break;
        default:
            break;
    }

    [_closeButton setFrame:closeButtonFrame];

    if (![self useCustomClose]) {
        [_closeButton setImage:_closeImageNormal forState:UIControlStateNormal];
        [_closeButton setImage:_closeImageHighlighted forState:UIControlStateHighlighted];
    } else {
        [_closeButton setImage:nil forState:UIControlStateNormal];
        [_closeButton setImage:nil forState:UIControlStateHighlighted];
    }
}

#pragma mark - UIVIew

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [_webView setFrame:frame];
    [_loadingIndicator setFrame:frame];

    [self updateCloseButton];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (_state == MNMRAIDStateLoading) {
        [self setState:MNMRAIDStateDefault];
        [self fireReady];
        [self updateCloseButton];

        if ([_delegate respondsToSelector:@selector(mraidDidLoad)]) {
            [_delegate mraidDidLoad];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(mraidDidFail)]) {
        [_delegate mraidDidFail];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];

    if ([[url scheme] isEqualToString:@"mraid"]) {
        NSString *command = [url host];
        NSMutableDictionary *arguments = [NSMutableDictionary dictionary];

        for (NSString *component in [[url query] componentsSeparatedByString:@"&"]) {
            NSArray *nameValuePair = [component componentsSeparatedByString:@"="];

            if ([nameValuePair count]) {
                NSString *name = [nameValuePair objectAtIndex:0];
                NSString *value = nil;

                if ([nameValuePair count] > 1) {
                    value = [[[nameValuePair objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }

                [arguments setObject:value forKey:name];
            }
        }

        if ([command isEqualToString:@"resize"]) {
            [self resize];
        } else if ([command isEqualToString:@"expand"]) {
            [self expand:[NSURL URLWithString:arguments[@"url"]]];
        } else if ([command isEqualToString:@"close"]) {
            [self close];
        } else if ([command isEqualToString:@"open"]) {
            [self open:[NSURL URLWithString:arguments[@"url"]]];
        } else {
            [self command:command arguments:arguments];
        }

        return NO;
    } else if (_state != MNMRAIDStateLoading) {
        [self open:url];

        return NO;
    }

    return YES;
}

#pragma mark - MRAID

- (void)command:(NSString *)command arguments:(NSDictionary *)arguments
{
    if ([_delegate respondsToSelector:@selector(mraidCommand:arguments:)]) {
        [_delegate mraidCommand:command arguments:arguments];
    }
}

- (void)setState:(MNMRAIDState)state
{
    [self inject:[NSString stringWithFormat:@"mraid._setState(\"%@\");", stringFromState(state)]];

    _state = state;

    [self fireStateChange];
}

- (void)setIsViewable:(BOOL)isViewable
{
    [self inject:[NSString stringWithFormat:@"mraid._setIsViewable(%@);", isViewable ? @"true" : @"false"]];

    _isViewable = isViewable;

    [self fireViewableChange];
}

- (void)setPlacementType:(MNMRAIDPlacementType)placementType
{
    [self inject:[NSString stringWithFormat:@"mraid._setPlacementType(\"%@\");", stringFromPlacementType(placementType)]];

    _placementType = placementType;
}

- (void)open:(NSURL *)url
{
    if ([_delegate respondsToSelector:@selector(mraidShouldOpen:)]) {
        [_delegate mraidShouldOpen:url];
    }
}

- (void)expand:(NSURL *)url
{
    if (_state == MNMRAIDStateDefault || _state == MNMRAIDStateResized) {
        [self setState:MNMRAIDStateExpanded];

        if ([_delegate respondsToSelector:@selector(mraidShouldExpand:)]) {
            [_delegate mraidShouldExpand:url];
        }
    }
}

- (long)expandWidth
{
    NSNumber *expandWidth = [[[NSNumberFormatter alloc] init] numberFromString:[self inject:@"mraid._getExpandPropertyWidth();"]];

    if (expandWidth) {
        _expandWidth = [expandWidth longValue];
    } else {
        [self setExpandWidth:_expandWidth];
    }

    return _expandWidth;
}

- (void)setExpandWidth:(long)expandWidth
{
    [self inject:[NSString stringWithFormat:@"mraid._setExpandPropertyWidth(%li);", expandWidth]];

    _expandWidth = expandWidth;
}

- (long)expandHeight
{
    NSNumber *expandHeight = [[[NSNumberFormatter alloc] init] numberFromString:[self inject:@"mraid._getExpandPropertyHeight();"]];

    if (expandHeight) {
        _expandWidth = [expandHeight longValue];
    } else {
        [self setExpandHeight:_expandHeight];
    }

    return _expandHeight;
}

- (void)setExpandHeight:(long)expandHeight
{
    [self inject:[NSString stringWithFormat:@"mraid._setExpandPropertyHeight(%li);", expandHeight]];

    _expandHeight = expandHeight;
}

- (BOOL)useCustomClose
{
    NSString *useCustomClose = [self inject:@"mraid._getExpandPropertyUseCustomClose();"];

    if (![useCustomClose isEqualToString:@"true"] && ![useCustomClose isEqualToString:@"false"]) {
        [self setUseCustomClose:_useCustomClose];
    } else if ([useCustomClose isEqualToString:@"true"]) {
        _useCustomClose = YES;
    } else if ([useCustomClose isEqualToString:@"false"]) {
        _useCustomClose = NO;
    }

    return _useCustomClose;
}

- (void)setUseCustomClose:(BOOL)useCustomClose
{
    [self inject:[NSString stringWithFormat:@"mraid._setExpandPropertyUseCustomClose(%@);", useCustomClose ? @"true" : @"false"]];

    _useCustomClose = useCustomClose;
}

- (BOOL)allowOrientationChange
{
    NSString *allowOrientationChange = [self inject:@"mraid._getOrientationPropertyAllowOrientationChange();"];

    if (![allowOrientationChange isEqualToString:@"true"] && ![allowOrientationChange isEqualToString:@"false"]) {
        [self setAllowOrientationChange:_allowOrientationChange];
    } else if ([allowOrientationChange isEqualToString:@"true"]) {
        _allowOrientationChange = YES;
    } else if ([allowOrientationChange isEqualToString:@"false"]) {
        _allowOrientationChange = NO;
    }

    return _allowOrientationChange;
}

- (void)setAllowOrientationChange:(BOOL)allowOrientationChange
{
    [self inject:[NSString stringWithFormat:@"mraid._setOrientationPropertyAllowOrientationChange(%@);", allowOrientationChange ? @"true" : @"false"]];

    _allowOrientationChange = allowOrientationChange;
}

- (MNMRAIDOrientation)forceOrientation
{
    NSString *orientation = [self inject:@"mraid._getOrientationPropertyForceOrientation();"];

    if (![orientation isEqualToString:@"portrait"] && ![orientation isEqualToString:@"landscape"] && ![orientation isEqualToString:@"none"]) {
        [self setForceOrientation:_forceOrientation];
    } else if ([orientation isEqualToString:@"portrait"]) {
        _forceOrientation = MNMRAIDOrientationPortrait;
    } else if ([orientation isEqualToString:@"landscape"]) {
        _forceOrientation = MNMRAIDOrientationLandscape;
    } else if ([orientation isEqualToString:@"none"]) {
        _forceOrientation = MNMRAIDOrientationNone;
    }

    return _forceOrientation;
}

- (void)setForceOrientation:(MNMRAIDOrientation)orientation
{
    [self inject:[NSString stringWithFormat:@"mraid._setOrientationPropertyForceOrientation(\"%@\");", stringFromOrientation(orientation)]];

    _forceOrientation = orientation;
}

- (void)resize
{
    if ((_placementType == MNMRAIDPlacementTypeInline && _state == MNMRAIDStateDefault) || _state == MNMRAIDStateResized) {
        [self setState:MNMRAIDStateResized];
        [self setCurrentPosition:CGRectMake(_currentPosition.origin.x + _resizeOffsetX, _currentPosition.origin.y + _resizeOffsetY, _resizeWidth, _resizeHeight)];

        if ([_delegate respondsToSelector:@selector(mraidShouldResize)]) {
            [_delegate mraidShouldResize];
        }
    } else if (_state == MNMRAIDStateExpanded) {
        [self fireError:@"" action:@"resize"];
    }
}

- (long)resizeWidth
{
    NSNumber *resizeWidth = [[[NSNumberFormatter alloc] init] numberFromString:[self inject:@"mraid._getResizePropertyWidth();"]];

    if (resizeWidth) {
        _resizeWidth = [resizeWidth longValue];
    } else {
        [self setResizeWidth:_resizeWidth];
    }

    return _resizeWidth;
}

- (void)setResizeWidth:(long)resizeWidth
{
    [self inject:[NSString stringWithFormat:@"mraid._setResizePropertyWidth(%li);", resizeWidth]];

    _resizeWidth = resizeWidth;
}

- (long)resizeHeight
{
    NSNumber *resizeHeight = [[[NSNumberFormatter alloc] init] numberFromString:[self inject:@"mraid._getResizePropertyHeight();"]];

    if (resizeHeight) {
        _resizeHeight = [resizeHeight longValue];
    } else {
        [self setResizeHeight:_resizeHeight];
    }

    return _resizeHeight;
}

- (void)setResizeHeight:(long)resizeHeight
{
    [self inject:[NSString stringWithFormat:@"mraid._setResizePropertyHeight(%li);", resizeHeight]];

    _resizeHeight = resizeHeight;
}

- (long)resizeOffsetX
{
    NSNumber *resizeOffsetX = [[[NSNumberFormatter alloc] init] numberFromString:[self inject:@"mraid._getResizePropertyOffsetX();"]];

    if (resizeOffsetX) {
        _resizeOffsetX = [resizeOffsetX longValue];
    } else {
        [self setResizeOffsetX:_resizeOffsetX];
    }

    return _resizeOffsetX;
}

- (void)setResizeOffsetX:(long)resizeOffsetX
{
    [self inject:[NSString stringWithFormat:@"mraid._setResizePropertyOffsetX(%li);", resizeOffsetX]];

    _resizeOffsetX = resizeOffsetX;
}

- (long)resizeOffsetY
{
    NSNumber *resizeOffsetY = [[[NSNumberFormatter alloc] init] numberFromString:[self inject:@"mraid._getResizePropertyOffsetY();"]];

    if (resizeOffsetY) {
        _resizeOffsetY = [resizeOffsetY longValue];
    } else {
        [self setResizeOffsetY:_resizeOffsetY];
    }

    return _resizeOffsetY;
}

- (void)setResizeOffsetY:(long)resizeOffsetY
{
    [self inject:[NSString stringWithFormat:@"mraid._setResizePropertyOffsetY(%li);", resizeOffsetY]];

    _resizeOffsetY = resizeOffsetY;
}

- (MNMRAIDPosition)customClosePosition
{
    NSString *customClosePosition = [self inject:@"mraid._getResizePropertyCustomClosePosition();"];

    if (![customClosePosition isEqualToString:@"top-left"] && ![customClosePosition isEqualToString:@"top-right"] && ![customClosePosition isEqualToString:@"bottom-left"] && ![customClosePosition isEqualToString:@"bottom-right"] && ![customClosePosition isEqualToString:@"top-center"] && ![customClosePosition isEqualToString:@"bottom-center"]) {
        [self setCustomClosePosition:_customClosePosition];
    } else if ([customClosePosition isEqualToString:@"top-left"]) {
        _customClosePosition = MNMRAIDPositionTopLeft;
    } else if ([customClosePosition isEqualToString:@"top-right"]) {
        _customClosePosition = MNMRAIDPositionTopRight;
    } else if ([customClosePosition isEqualToString:@"bottom-left"]) {
        _customClosePosition = MNMRAIDPositionBottomLeft;
    } else if ([customClosePosition isEqualToString:@"bottom-right"]) {
        _customClosePosition = MNMRAIDPositionBottomRight;
    } else if ([customClosePosition isEqualToString:@"top-center"]) {
        _customClosePosition = MNMRAIDPositionTopCenter;
    } else if ([customClosePosition isEqualToString:@"bottom-center"]) {
        _customClosePosition = MNMRAIDPositionBottomCenter;
    }

    return _customClosePosition;
}

- (void)setCustomClosePosition:(MNMRAIDPosition)customClosePosition
{
    [self inject:[NSString stringWithFormat:@"mraid._setResizePropertyCustomClosePosition(\"%@\");", stringFromPosition(customClosePosition)]];

    _customClosePosition = customClosePosition;
}

- (BOOL)allowOffscreen
{
    NSString *allowOffscreen = [self inject:@"mraid._getResizePropertyAllowOffscreen();"];

    if (![allowOffscreen isEqualToString:@"true"] && ![allowOffscreen isEqualToString:@"false"]) {
        [self setAllowOffscreen:_allowOffscreen];
    } else if ([allowOffscreen isEqualToString:@"true"]) {
        _allowOffscreen = YES;
    } else if ([allowOffscreen isEqualToString:@"false"]) {
        _allowOffscreen = NO;
    }

    return _allowOffscreen;
}

- (void)setAllowOffscreen:(BOOL)allowOffscreen
{
    [self inject:[NSString stringWithFormat:@"mraid._setResizePropertyAllowOffscreen(%@);", allowOffscreen ? @"true" : @"false"]];

    _allowOffscreen = allowOffscreen;
}

- (void)close
{
    if (_placementType == MNMRAIDPlacementTypeInterstitial && _state == MNMRAIDStateDefault) {
        [self setState:MNMRAIDStateHidden];

        if ([_delegate respondsToSelector:@selector(mraidShouldClose)]){
            [_delegate mraidShouldClose];
        }
    } else if (_state == MNMRAIDStateExpanded || _state == MNMRAIDStateResized) {
        [self setState:MNMRAIDStateDefault];

        if ([_delegate respondsToSelector:@selector(mraidShouldClose)]) {
            [_delegate mraidShouldClose];
        }
    }
}

- (void)setCurrentPosition:(CGRect)currentPosition
{
    [self inject:[NSString stringWithFormat:@"mraid._setCurrentPosition(%.0f, %.0f, %.0f, %.0f);", currentPosition.origin.x, currentPosition.origin.y, currentPosition.size.width, currentPosition.size.height]];

    _currentPosition = currentPosition;

    [self fireSizeChange];
}

- (void)setMaxSize:(CGSize)maxSize
{
    [self inject:[NSString stringWithFormat:@"mraid._setMaxSize(%.0f, %.0f);", maxSize.width, maxSize.height]];

    _maxSize = maxSize;
}

- (void)setDefaultPosition:(CGRect)defaultPosition
{
    [self inject:[NSString stringWithFormat:@"mraid._setDefaultPosition(%.0f, %.0f, %.0f, %.0f);", defaultPosition.origin.x, defaultPosition.origin.y, defaultPosition.size.width, defaultPosition.size.height]];

    _defaultPosition = defaultPosition;
}

- (void)setScreenSize:(CGSize)screenSize
{
    [self inject:[NSString stringWithFormat:@"mraid._setScreenSize(%.0f, %.0f);", screenSize.width, screenSize.height]];
    
    _screenSize = screenSize;
}

- (void)setSupportsInlineVideo:(BOOL)supportsInlineVideo
{
    if (supportsInlineVideo) {
        [self inject:[NSString stringWithFormat:@"mraid._addFeature(\"inlineVideo\");"]];
    } else {
        [self inject:[NSString stringWithFormat:@"mraid._removeFeature(\"inlineVideo\");"]];
    }
}

- (void)fireReady
{
    [self inject:[NSString stringWithFormat:@"mraid._fireEvent(\"ready\");"]];
}

- (void)fireError:(NSString *)message action:(NSString *)action
{
    [self inject:[NSString stringWithFormat:@"mraid._fireEvent(\"error\", \"%@\", \"%@\");", message, action]];
}

- (void)fireStateChange
{
    [self inject:[NSString stringWithFormat:@"mraid._fireEvent(\"stateChange\", \"%@\");", stringFromState(_state)]];
}

- (void)fireViewableChange
{
    [self inject:[NSString stringWithFormat:@"mraid._fireEvent(\"viewableChange\", %@);", _isViewable ? @"true" : @"false"]];
}

- (void)fireSizeChange
{
    [self inject:[NSString stringWithFormat:@"mraid._fireEvent(\"sizeChange\", %.0f, %0f);", _currentPosition.size.width, _currentPosition.size.height]];
}

@end

NSString *stringFromState(MNMRAIDState state) {
    NSString *stateString = nil;

    switch (state) {
        case MNMRAIDStateLoading:
            stateString = @"loading";
            break;
        case MNMRAIDStateDefault:
            stateString = @"default";
            break;
        case MNMRAIDStateExpanded:
            stateString = @"expanded";
            break;
        case MNMRAIDStateResized:
            stateString = @"resized";
            break;
        case MNMRAIDStateHidden:
            stateString = @"hidden";
            break;
        default:
            break;
    }

    return stateString;
}

NSString *stringFromOrientation(MNMRAIDOrientation orientation) {
    NSString *orientationString = nil;

    switch (orientation) {
        case MNMRAIDOrientationPortrait:
            orientationString = @"portrait";
            break;
        case MNMRAIDOrientationLandscape:
            orientationString = @"landscape";
            break;
        case MNMRAIDOrientationNone:
            orientationString = @"none";
            break;
        default:
            break;
    }

    return orientationString;
}

NSString *stringFromPlacementType(MNMRAIDPlacementType placementType) {
    NSString *placementTypeString = nil;

    switch (placementType) {
        case MNMRAIDPlacementTypeInline:
            placementTypeString = @"inline";
            break;
        case MNMRAIDPlacementTypeInterstitial:
            placementTypeString = @"interstitial";
            break;
        default:
            break;
    }

    return placementTypeString;
}

NSString *stringFromPosition(MNMRAIDPosition position) {
    NSString *positionString = nil;

    switch (position) {
        case MNMRAIDPositionTopLeft:
            positionString = @"top-left";
            break;
        case MNMRAIDPositionTopRight:
            positionString = @"top-right";
            break;
        case MNMRAIDPositionBottomLeft:
            positionString = @"bottom-left";
            break;
        case MNMRAIDPositionBottomRight:
            positionString = @"bottom-right";
            break;
        case MNMRAIDPositionTopCenter:
            positionString = @"top-center";
            break;
        case MNMRAIDPositionBottomCenter:
            positionString = @"bottom-center";
            break;
        default:
            break;
    }
    
    return positionString;
}
