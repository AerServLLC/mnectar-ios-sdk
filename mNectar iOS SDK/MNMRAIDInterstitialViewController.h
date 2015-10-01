#import <UIKit/UIKit.h>
#import "MNMRAIDView.h"

@class MNMRAIDInterstitialViewController;

@protocol MNMRAIDInterstitialViewControllerDelegate <NSObject>

@optional
- (void)interstitialViewControllerDidLoad:(MNMRAIDInterstitialViewController *)interstitial;
- (void)interstitialViewControllerDidFail:(MNMRAIDInterstitialViewController *)interstitial;
- (void)interstitialViewControllerWillAppear:(MNMRAIDInterstitialViewController *)interstitial;
- (void)interstitialViewControllerDidAppear:(MNMRAIDInterstitialViewController *)interstitial;
- (void)interstitialViewControllerWillDismiss:(MNMRAIDInterstitialViewController *)interstitial;
- (void)interstitialViewControllerDidDismiss:(MNMRAIDInterstitialViewController *)interstitial;
- (void)interstitialViewControllerBridge:(MNMRAIDInterstitialViewController *)interstitial command:(NSString *)command arguments:(NSDictionary *)arguments;

@end

@interface MNMRAIDInterstitialViewController : UIViewController

@property (nonatomic, strong) MNMRAIDView *mraidView;

@property (nonatomic, weak) id<MNMRAIDInterstitialViewControllerDelegate> delegate;

- (instancetype)initWithDelegate:(id<MNMRAIDInterstitialViewControllerDelegate>)delegate;

- (void)loadHTML:(NSString *)html baseURL:(NSURL *)baseURL;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)show;

@end
