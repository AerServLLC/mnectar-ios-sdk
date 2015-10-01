#import <UIKit/UIKit.h>

@class MNInterstitial;

@protocol MNInterstitialDelegate <NSObject>

@optional
- (void)interstitialDidLoad:(MNInterstitial *)interstitial;
- (void)interstitialDidFail:(MNInterstitial *)interstitial;
- (void)interstitialWillAppear:(MNInterstitial *)interstitial;
- (void)interstitialDidAppear:(MNInterstitial *)interstitial;
- (void)interstitialWillDismiss:(MNInterstitial *)interstitial;
- (void)interstitialDidDismiss:(MNInterstitial *)interstitial;

@end

@interface MNInterstitial : NSObject

@property (nonatomic, weak) id<MNInterstitialDelegate> delegate;
@property (nonatomic, assign) BOOL prefetch;
@property (nonatomic, assign, readonly, getter=isAdReady) BOOL adReady;

+ (instancetype)interstitialForAdUnitId:(NSString *)adUnitId;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId;

- (void)loadAd;
- (void)showAdFromViewController:(UIViewController *)viewController;
- (void)showAd;

@end

@interface MNReward : NSObject

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSNumber *amount;

- (MNReward *)initWithType:(NSString *)type amount:(NSNumber *)amount;
- (MNReward *)initWithAmount:(NSNumber *)amount;

@end
