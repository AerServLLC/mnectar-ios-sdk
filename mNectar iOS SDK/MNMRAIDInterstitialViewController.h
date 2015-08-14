#import <UIKit/UIKit.h>
#import "MNMRAIDView.h"

@class MNMRAIDInterstitialViewController;

@protocol MNMRAIDInterstitialViewControllerDelegate <NSObject>

@optional
- (void)interstitialViewControllerDidLoad;
- (void)interstitialViewControllerDidFail;
- (void)interstitialViewControllerWillAppear;
- (void)interstitialViewControllerWillDismiss;
- (void)interstitialViewControllerCommand:(NSString *)command arguments:(NSDictionary *)arguments;

@end

@interface MNMRAIDInterstitialViewController : UIViewController

@property (nonatomic, strong) MNMRAIDView *mraidView;

@property (nonatomic, weak) id<MNMRAIDInterstitialViewControllerDelegate> delegate;

- (instancetype)initWithHTML:(NSString *)html baseURL:(NSURL *)baseURL;

- (void)showFromViewController:(UIViewController *)viewController;
- (void)show;

@end
