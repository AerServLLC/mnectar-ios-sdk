#import "MNMRAIDView.h"
#import "MNWebView.h"

#define MN_IMG_CLOSE_NORMAL "MNMRAID.bundle/cancel"
#define MN_IMG_CLOSE_HIGHLIGHTED "MNMRAID.bundle/cancel_white"

@interface MNMRAIDView () <MNWebViewDelegate>

//@property (nonatomic, strong) UIWebView *oldWebView;
//@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) MNWebView *webView;

@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIImage *closeImageNormal;
@property (nonatomic, strong) UIImage *closeImageHighlighted;


@property (nonatomic, assign) MNMRAIDState state;

@property (nonatomic, assign) CGSize expandSize;
@property (nonatomic, assign) CGRect resizePosition;
@property (nonatomic, assign) MNMRAIDPosition customClosePosition;
@property (nonatomic, assign) BOOL allowOffscreen;
@property (nonatomic, assign) CGRect currentPosition;
@property (nonatomic, assign) CGRect defaultPosition;
@property (nonatomic, assign) BOOL supportsInlineVideo;
@end

@implementation MNMRAIDView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
        _webView = [[MNWebView alloc] initWithFrame:frame];
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

        [self inject:[[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MNMRAID.bundle/mraidjs" ofType:nil] encoding:NSUTF8StringEncoding error:nil]];
        [self setState:MNMRAIDStateLoading];
        [self setPlacementType:MNMRAIDPlacementTypeInline];
        [self setIsViewable:NO];
        [self setExpandSize:screen.size];
        [self setUseCustomClose:NO];
        [self setAllowOrientationChange:YES];
        [self setForceOrientation:MNMRAIDOrientationNone];
        [self setResizePosition:screen];
        [self setCustomClosePosition:MNMRAIDPositionTopRight];
        [self setAllowOffscreen:YES];
        [self setCurrentPosition:frame];
        [self setMaxSize:screen.size];
        [self setDefaultPosition:frame];
        [self setScreenSize:screen.size];
        [self setSupportsInlineVideo:YES];

        [self inject:@"window.addEventListener(\"load\", function () { mraid._call(\"load\"); });"];
    }

    return self;
}

- (void)inject:(NSString *)js
{

    [_webView evaluateJavaScriptFromString:js];
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

- (void)dispatchOrientationChange
{
    [self inject:@"var event = document.createEvent('OrientationEvent'); event.initEvent('orientationchange', false, false); window.dispatchEvent(event);"];
}

- (void)loadHTML:(NSString *)html baseURL:(NSURL *)baseURL
{
        [_webView loadHTML:html baseURL:baseURL];
}

#pragma mark - UIVIew

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [_webView setFrame:frame];

    [_loadingIndicator setFrame:frame];

    [self updateCloseButton];

    [self setCurrentPosition:[self frame]];
    [self fireSizeChange];
}

#pragma mark - MNWebViewDelegate

- (void)webView:(MNWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(mraidDidFail:)]) {
        [_delegate mraidDidFail:self];
    }
}

- (BOOL)webView:(MNWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
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

        if ([command isEqualToString:@"load"]) {
            if (_state == MNMRAIDStateLoading) {
                [self setState:MNMRAIDStateDefault];
                [self fireReady];
                [self updateCloseButton];
                [self dispatchOrientationChange];

                if ([_delegate respondsToSelector:@selector(mraidDidLoad:)]) {
                    [_delegate mraidDidLoad:self];
                }
            }
        } else if ([command isEqualToString:@"expandProperties"]) {
            NSNumber *width = [[[NSNumberFormatter alloc] init] numberFromString:arguments[@"width"]];
            NSNumber *height = [[[NSNumberFormatter alloc] init] numberFromString:arguments[@"height"]];

            if (width && height) {
                _expandSize = CGSizeMake([width floatValue], [height floatValue]);
            }

            NSString *useCustomClose = arguments[@"useCustomClose"];

            if (useCustomClose && [useCustomClose isEqualToString:@"true"]) {
                _useCustomClose = YES;
            } else if (useCustomClose && [useCustomClose isEqualToString:@"false"]) {
                _useCustomClose = NO;
            }

            [self updateCloseButton];
        } else if ([command isEqualToString:@"expand"]) {
            [self expand:[NSURL URLWithString:arguments[@"url"]]];
        } else if ([command isEqualToString:@"orientationProperties"]) {
            NSString *allowOrientationChange = arguments[@"allowOrientationChange"];

            if (allowOrientationChange && [allowOrientationChange isEqualToString:@"true"]) {
                _allowOrientationChange = YES;
            } else if (allowOrientationChange && [allowOrientationChange isEqualToString:@"false"]) {
                _allowOrientationChange = NO;
            }

            NSString *forceOrientation = arguments[@"forceOrientation"];

            if ([forceOrientation isEqualToString:@"portrait"]) {
                _forceOrientation = MNMRAIDOrientationPortrait;
            } else if ([forceOrientation isEqualToString:@"landscape"]) {
                _forceOrientation = MNMRAIDOrientationLandscape;
            } else if ([forceOrientation isEqualToString:@"none"]) {
                _forceOrientation = MNMRAIDOrientationNone;
            }

            if ([_delegate respondsToSelector:@selector(mraidShouldReorient:)]) {
                [_delegate mraidShouldReorient:self];
            }
        } else if ([command isEqualToString:@"resizeProperties"]) {
            NSNumber *offsetX = [[[NSNumberFormatter alloc] init] numberFromString:arguments[@"offsetX"]];
            NSNumber *offsetY = [[[NSNumberFormatter alloc] init] numberFromString:arguments[@"offsetY"]];
            NSNumber *width = [[[NSNumberFormatter alloc] init] numberFromString:arguments[@"width"]];
            NSNumber *height = [[[NSNumberFormatter alloc] init] numberFromString:arguments[@"height"]];

            if (offsetX && offsetY && width && height) {
                _resizePosition = CGRectMake([offsetX floatValue], [offsetY floatValue], [width floatValue], [height floatValue]);
            }

            NSString *customClosePosition = arguments[@"customClosePosition"];

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

            NSString *allowOffscreen = arguments[@"allowOffscreen"];

            if (allowOffscreen && [allowOffscreen isEqualToString:@"true"]) {
                _allowOffscreen = YES;
            } else if (allowOffscreen && [allowOffscreen isEqualToString:@"false"]) {
                _allowOffscreen = NO;
            }
        } else if ([command isEqualToString:@"resize"]) {
            [self resize];
        } else if ([command isEqualToString:@"close"]) {
            [self close];
        } else if ([command isEqualToString:@"open"]) {
            [self open:[NSURL URLWithString:arguments[@"url"]]];
        } else if ([command isEqualToString:@"log"]) {
            NSLog(@"%@", arguments[@"message"]);
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
    if ([_delegate respondsToSelector:@selector(mraidBridge:command:arguments:)]) {
        [_delegate mraidBridge:self command:command arguments:arguments];
    }
}

- (void)setState:(MNMRAIDState)state
{
    [self inject:[NSString stringWithFormat:@"mraid._setState(\"%@\");", stringFromState(state)]];

    _state = state;

    [self fireStateChange];
}

- (void)setPlacementType:(MNMRAIDPlacementType)placementType
{
    [self inject:[NSString stringWithFormat:@"mraid._setPlacementType(\"%@\");", stringFromPlacementType(placementType)]];

    _placementType = placementType;
}

- (void)setIsViewable:(BOOL)isViewable
{
    [self inject:[NSString stringWithFormat:@"mraid._setIsViewable(%@);", isViewable ? @"true" : @"false"]];

    _isViewable = isViewable;

    [self fireViewableChange];
}

- (void)open:(NSURL *)url
{
    if ([_delegate respondsToSelector:@selector(mraidShouldOpen:url:)]) {
        [_delegate mraidShouldOpen:self url:url];
    }
}

- (void)expand:(NSURL *)url
{
    if (_state == MNMRAIDStateDefault || _state == MNMRAIDStateResized) {
        [self setState:MNMRAIDStateExpanded];

        if ([_delegate respondsToSelector:@selector(mraidShouldExpand:url:)]) {
            [_delegate mraidShouldExpand:self url:url];
        }
    }
}

- (void)setExpandSize:(CGSize)expandSize
{
    [self inject:[NSString stringWithFormat:@"mraid._setExpandSize(%.0f, %.0f);", expandSize.width, expandSize.height]];

    _expandSize = expandSize;
}

- (void)setUseCustomClose:(BOOL)useCustomClose
{
    [self inject:[NSString stringWithFormat:@"mraid._setExpandPropertyUseCustomClose(%@);", useCustomClose ? @"true" : @"false"]];

    _useCustomClose = useCustomClose;
}

- (void)setAllowOrientationChange:(BOOL)allowOrientationChange
{
    [self inject:[NSString stringWithFormat:@"mraid._setOrientationPropertyAllowOrientationChange(%@);", allowOrientationChange ? @"true" : @"false"]];

    _allowOrientationChange = allowOrientationChange;
}

- (void)setForceOrientation:(MNMRAIDOrientation)forceOrientation
{
    [self inject:[NSString stringWithFormat:@"mraid._setOrientationPropertyForceOrientation(\"%@\");", stringFromOrientation(forceOrientation)]];

    _forceOrientation = forceOrientation;
}

- (void)resize
{
    if ((_placementType == MNMRAIDPlacementTypeInline && _state == MNMRAIDStateDefault) || _state == MNMRAIDStateResized) {
        [self setState:MNMRAIDStateResized];
        [self setCurrentPosition:CGRectMake(_currentPosition.origin.x + _resizePosition.origin.x, _currentPosition.origin.y + _resizePosition.origin.y, _resizePosition.size.width, _resizePosition.size.height)];

        if ([_delegate respondsToSelector:@selector(mraidShouldResize:)]) {
            [_delegate mraidShouldResize:self];
        }
    } else if (_state == MNMRAIDStateExpanded) {
        [self fireError:@"" action:@"resize"];
    }
}

- (void)setResizePosition:(CGRect)resizePosition
{
    [self inject:[NSString stringWithFormat:@"mraid._setResizePosition(%.0f, %.0f, %.0f, %.0f);", resizePosition.origin.x, resizePosition.origin.y, resizePosition.size.width, resizePosition.size.height]];

    _resizePosition = resizePosition;
}

- (void)setCustomClosePosition:(MNMRAIDPosition)customClosePosition
{
    [self inject:[NSString stringWithFormat:@"mraid._setResizePropertyCustomClosePosition(\"%@\");", stringFromPosition(customClosePosition)]];

    _customClosePosition = customClosePosition;
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

        if ([_delegate respondsToSelector:@selector(mraidShouldClose:)]){
            [_delegate mraidShouldClose:self];
        }
    } else if (_state == MNMRAIDStateExpanded || _state == MNMRAIDStateResized) {
        [self setState:MNMRAIDStateDefault];

        if ([_delegate respondsToSelector:@selector(mraidShouldClose:)]) {
            [_delegate mraidShouldClose:self];
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
