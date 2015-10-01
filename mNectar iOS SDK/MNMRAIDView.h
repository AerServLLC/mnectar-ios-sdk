#import <UIKit/UIKit.h>

typedef enum {
    MNMRAIDStateLoading,
    MNMRAIDStateDefault,
    MNMRAIDStateExpanded,
    MNMRAIDStateResized,
    MNMRAIDStateHidden
} MNMRAIDState;

typedef enum {
    MNMRAIDOrientationPortrait,
    MNMRAIDOrientationLandscape,
    MNMRAIDOrientationNone
} MNMRAIDOrientation;

typedef enum {
    MNMRAIDPlacementTypeInline,
    MNMRAIDPlacementTypeInterstitial
} MNMRAIDPlacementType;

typedef enum {
    MNMRAIDPositionTopLeft,
    MNMRAIDPositionTopRight,
    MNMRAIDPositionBottomLeft,
    MNMRAIDPositionBottomRight,
    MNMRAIDPositionTopCenter,
    MNMRAIDPositionBottomCenter
} MNMRAIDPosition;

@class MNMRAIDView;

@protocol MNMRAIDViewDelegate <NSObject>

@optional
- (void)mraidDidLoad:(MNMRAIDView *)mraid;
- (void)mraidDidFail:(MNMRAIDView *)mraid;

- (void)mraidShouldReorient:(MNMRAIDView *)mraid;
- (void)mraidShouldExpand:(MNMRAIDView *)mraid url:(NSURL *)url;
- (void)mraidShouldResize:(MNMRAIDView *)mraid;
- (void)mraidShouldClose:(MNMRAIDView *)mraid;
- (void)mraidShouldOpen:(MNMRAIDView *)mraid url:(NSURL *)url;
- (void)mraidBridge:(MNMRAIDView *)mraid command:(NSString *)command arguments:(NSDictionary *)arguments;

@end

@interface MNMRAIDView : UIView

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIImage *closeImageNormal;
@property (nonatomic, strong) UIImage *closeImageHighlighted;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, weak) id<MNMRAIDViewDelegate> delegate;

@property (nonatomic, assign) MNMRAIDState state;
@property (nonatomic, assign) MNMRAIDPlacementType placementType;
@property (nonatomic, assign) BOOL isViewable;
@property (nonatomic, assign) CGSize expandSize;
@property (nonatomic, assign) BOOL useCustomClose;
@property (nonatomic, assign) BOOL allowOrientationChange;
@property (nonatomic, assign) MNMRAIDOrientation forceOrientation;
@property (nonatomic, assign) CGRect resizePosition;
@property (nonatomic, assign) MNMRAIDPosition customClosePosition;
@property (nonatomic, assign) BOOL allowOffscreen;
@property (nonatomic, assign) CGRect currentPosition;
@property (nonatomic, assign) CGSize maxSize;
@property (nonatomic, assign) CGRect defaultPosition;
@property (nonatomic, assign) CGSize screenSize;
@property (nonatomic, assign) BOOL supportsInlineVideo;

- (instancetype)initWithFrame:(CGRect)frame;

- (NSString *)inject:(NSString *)js;
- (void)updateCloseButton;
- (void)startLoading;
- (void)stopLoading;
- (void)dispatchOrientationChange;

- (void)fireReady;
- (void)fireError:(NSString *)message action:(NSString *)action;
- (void)fireStateChange;
- (void)fireViewableChange;
- (void)fireSizeChange;

- (void)command:(NSString *)command arguments:(NSDictionary *)arguments;
- (void)open:(NSURL *)url;
- (void)expand:(NSURL *)url;
- (void)resize;
- (void)close;

@end

NSString *stringFromState(MNMRAIDState state);
NSString *stringFromOrientation(MNMRAIDOrientation orientation);
NSString *stringFromPlacementType(MNMRAIDPlacementType placementType);
NSString *stringFromPosition(MNMRAIDPosition position);

