#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

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

@property (nonatomic, assign) MNMRAIDPlacementType placementType;
@property (nonatomic, weak) id<MNMRAIDViewDelegate> delegate;
@property (nonatomic, assign) BOOL isViewable;
@property (nonatomic, assign) BOOL allowOrientationChange;
@property (nonatomic, assign) MNMRAIDOrientation forceOrientation;
@property (nonatomic, assign) BOOL useCustomClose;
@property (nonatomic, assign) CGSize maxSize;
@property (nonatomic, assign) CGSize screenSize;
@property (nonatomic, strong) UIButton *closeButton;


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
- (void)loadHTML:(NSString *)html baseURL:(NSURL *)baseURL;

@end

NSString *stringFromState(MNMRAIDState state);
NSString *stringFromOrientation(MNMRAIDOrientation orientation);
NSString *stringFromPlacementType(MNMRAIDPlacementType placementType);
NSString *stringFromPosition(MNMRAIDPosition position);

