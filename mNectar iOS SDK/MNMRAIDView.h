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
- (void)mraidDidLoad;
- (void)mraidDidFail;
- (void)mraidShouldExpand:(NSURL *)url;
- (void)mraidShouldResize;
- (void)mraidShouldClose;
- (void)mraidShouldOpen:(NSURL *)url;
- (void)mraidCommand:(NSString *)command arguments:(NSDictionary *)arguments;

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
@property (nonatomic, assign) long expandWidth;
@property (nonatomic, assign) long expandHeight;
@property (nonatomic, assign) BOOL useCustomClose;
@property (nonatomic, assign) BOOL allowOrientationChange;
@property (nonatomic, assign) MNMRAIDOrientation forceOrientation;
@property (nonatomic, assign) long resizeWidth;
@property (nonatomic, assign) long resizeHeight;
@property (nonatomic, assign) long resizeOffsetX;
@property (nonatomic, assign) long resizeOffsetY;
@property (nonatomic, assign) MNMRAIDPosition customClosePosition;
@property (nonatomic, assign) BOOL allowOffscreen;
@property (nonatomic, assign) CGRect currentPosition;
@property (nonatomic, assign) CGSize maxSize;
@property (nonatomic, assign) CGRect defaultPosition;
@property (nonatomic, assign) CGSize screenSize;
@property (nonatomic, assign) BOOL supportsInlineVideo;

- (instancetype)initWithFrame:(CGRect)frame;

- (NSString *)inject:(NSString *)js;
- (void)startLoading;
- (void)stopLoading;

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

