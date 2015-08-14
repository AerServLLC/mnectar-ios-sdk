#import "MNInterstitial.h"
#import "MNMRAIDInterstitialViewController.h"
#import "MNAdClient.h"

@interface MNInterstitial () <MNMRAIDInterstitialViewControllerDelegate>

@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, strong) MNMRAIDInterstitialViewController *mraidInterstitialViewController;
@property (nonatomic, strong) MNAdClient *adClient;
@property (nonatomic, assign, getter=isAdLoading) BOOL adLoading;
@property (nonatomic, assign, getter=isAdLoaded) BOOL adLoaded;

@end

@implementation MNInterstitial

@synthesize delegate = _delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
{
    if (self = [super init]) {
        _adUnitId = adUnitId;

        _adClient = [[MNAdClient alloc] initWithAdUnitId:_adUnitId];
        _adLoading = NO;
        _adLoaded = NO;
    }

    return self;
}

- (void)loadAd
{
    if (!_adLoading && !_adLoaded) {
        _adLoading = YES;

        [_adClient requestAd:^(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error) {
            _adLoading = NO;

            if (data && !error) {
                _mraidInterstitialViewController = [[MNMRAIDInterstitialViewController alloc] initWithHTML:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] baseURL:baseURL];
                [_mraidInterstitialViewController setDelegate:self];

                _adLoaded = YES;
            } else {
                [self interstitialViewControllerDidFail];
            }
        }];
    }
}

- (void)interstitialViewControllerDidLoad
{
    if ([_delegate respondsToSelector:@selector(interstitialDidLoad:)]) {
        [_delegate interstitialDidLoad:self];
    }
}
- (void)interstitialViewControllerDidFail
{
    _adLoaded = NO;

    if ([_delegate respondsToSelector:@selector(interstitialDidFail:)]) {
        [_delegate interstitialDidFail:self];
    }
}

- (void)interstitialViewControllerWillAppear
{
    if ([_delegate respondsToSelector:@selector(interstitialWillAppear:)]) {
        [_delegate interstitialWillAppear:self];
    }
}

- (void)interstitialViewControllerWillDismiss
{
    _adLoaded = NO;

    if ([_delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
        [_delegate interstitialWillDismiss:self];
    }
}

- (void)showAdFromViewController:(UIViewController *)viewController
{
    if (_adLoaded) {
        [_mraidInterstitialViewController showFromViewController:viewController];
    }
}

- (void)showAd
{
    [_mraidInterstitialViewController show];
}

@end
