#import "MNInterstitial.h"
#import "MNMRAIDInterstitialViewController.h"
#import "MNAdClient.h"

@interface MNInterstitial () <MNMRAIDInterstitialViewControllerDelegate>

@property (nonatomic, strong) MNMRAIDInterstitialViewController *mraidInterstitialViewController;
@property (nonatomic, strong) MNAdClient *adClient;

@end

static NSMutableDictionary *interstitials = nil;

@implementation MNInterstitial

+ (instancetype)interstitialForAdUnitId:(NSString *)adUnitId
{
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        interstitials = [[NSMutableDictionary alloc] init];
    });

    if (![interstitials objectForKey:adUnitId]) {
        [interstitials setObject:[[[self class] alloc] initWithAdUnitId:adUnitId] forKey:adUnitId];
    }

    return [interstitials objectForKey:adUnitId];
}

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
{
    if (self = [super init]) {
        _adReady = NO;

        _adClient = [[MNAdClient alloc] initWithAdUnitId:adUnitId];
    }

    return self;
}

- (void)loadAd
{
    if (!_mraidInterstitialViewController) {
        _mraidInterstitialViewController = [[MNMRAIDInterstitialViewController alloc] init];
        [_mraidInterstitialViewController setDelegate:self];

        [_adClient requestAd:^(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error) {
            if (data && !error) {
                [_mraidInterstitialViewController loadHTML:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] baseURL:baseURL];
            } else {
                [self interstitialViewControllerDidFail];
            }
        }];
    }
}

#pragma mark - MNMRAIDInterstitialViewControllerDelegate

- (void)interstitialViewControllerDidLoad
{
    _adReady = YES;

    if ([_delegate respondsToSelector:@selector(interstitialDidLoad:)]) {
        [_delegate interstitialDidLoad:self];
    }
}
- (void)interstitialViewControllerDidFail
{
    _adReady = NO;

    _mraidInterstitialViewController = nil;

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
    _adReady = NO;

    if ([_delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
        [_delegate interstitialWillDismiss:self];
    }

    _mraidInterstitialViewController = nil;
}

- (void)showAdFromViewController:(UIViewController *)viewController
{
    if (_mraidInterstitialViewController) {
        [_mraidInterstitialViewController showFromViewController:viewController];
    }
}

- (void)showAd
{
    [_mraidInterstitialViewController show];
}

@end
