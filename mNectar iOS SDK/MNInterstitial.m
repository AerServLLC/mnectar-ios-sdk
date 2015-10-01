#import "MNInterstitial.h"
#import "MNConstants.h"
#import "MNMRAIDInterstitialViewController.h"
#import "MNAdClient.h"

@interface MNInterstitial () <MNMRAIDInterstitialViewControllerDelegate>

@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, strong) MNMRAIDInterstitialViewController *mraidInterstitialViewController;
@property (nonatomic, strong) MNAdClient *adClient;
@property (nonatomic, assign) BOOL prefetchReady;
@property (nonatomic, strong) MNMRAIDInterstitialViewController *prefetchedMRAIDInterstitialViewController;
@property (nonatomic, strong) MNAdClient *prefetchedAdClient;

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
        _adUnitId = adUnitId;
        _adReady = NO;
        _prefetch = MN_PREFETCH;
        _prefetchReady = NO;

        if (_prefetch) {
            [self prefetchAd];
        }
    }

    return self;
}

- (void)setPrefetch:(BOOL)prefetch
{
    if (!prefetch && prefetch != _prefetch) {
        [_prefetchedMRAIDInterstitialViewController setDelegate:nil];

        _prefetchedAdClient = nil;
        _prefetchedMRAIDInterstitialViewController = nil;

        _prefetch = NO;
    } else if (prefetch && prefetch != _prefetch) {
        _prefetch = YES;

        [self prefetchAd];
    }
}

- (void)prefetchAd
{
    if (_prefetch && !_prefetchedAdClient) {
        _prefetchedAdClient = [[MNAdClient alloc] initWithAdUnitId:_adUnitId];
        _prefetchedMRAIDInterstitialViewController = [[MNMRAIDInterstitialViewController alloc] initWithDelegate:self];

        [_prefetchedAdClient requestAd:^(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error) {
            if (data && !error) {
                [_prefetchedMRAIDInterstitialViewController loadHTML:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] baseURL:baseURL];
            } else {
                [self interstitialViewControllerDidFail:_prefetchedMRAIDInterstitialViewController];
            }
        }];
    }
}

- (void)loadAd
{
    if (_prefetch && _prefetchReady && !_adReady) {
        _adClient = _prefetchedAdClient;
        _mraidInterstitialViewController = _prefetchedMRAIDInterstitialViewController;
        _adReady = _prefetchReady;

        _prefetchReady = NO;
        _prefetchedAdClient = nil;
        _prefetchedMRAIDInterstitialViewController = nil;

        [self interstitialViewControllerDidLoad:_mraidInterstitialViewController];
    } else if (!_adClient) {
        _adClient = [[MNAdClient alloc] initWithAdUnitId:_adUnitId];
        _mraidInterstitialViewController = [[MNMRAIDInterstitialViewController alloc] initWithDelegate:self];

        [_adClient requestAd:^(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error) {
            if (data && !error) {
                [_mraidInterstitialViewController loadHTML:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] baseURL:baseURL];
            } else {
                [self interstitialViewControllerDidFail:_mraidInterstitialViewController];
            }
        }];
    }
}

#pragma mark - MNMRAIDInterstitialViewControllerDelegate

- (void)interstitialViewControllerDidLoad:(MNMRAIDInterstitialViewController *)interstitial
{
    if (interstitial == _prefetchedMRAIDInterstitialViewController) {
        _prefetchReady = YES;
    } else {
        _adReady = YES;

        if ([_delegate respondsToSelector:@selector(interstitialDidLoad:)]) {
            [_delegate interstitialDidLoad:self];
        }
    }
}
- (void)interstitialViewControllerDidFail:(MNMRAIDInterstitialViewController *)interstitial
{
    if (interstitial == _prefetchedMRAIDInterstitialViewController) {
        _prefetchReady = NO;
        _prefetchedAdClient = nil;
        _prefetchedMRAIDInterstitialViewController = nil;
    } else {
        _adReady = NO;
        _adClient = nil;
        _mraidInterstitialViewController = nil;

        if ([_delegate respondsToSelector:@selector(interstitialDidFail:)]) {
            [_delegate interstitialDidFail:self];
        }
    }
}

- (void)interstitialViewControllerWillAppear:(MNMRAIDInterstitialViewController *)interstitial
{
    if ([_delegate respondsToSelector:@selector(interstitialWillAppear:)]) {
        [_delegate interstitialWillAppear:self];
    }
}

- (void)interstitialViewControllerDidAppear:(MNMRAIDInterstitialViewController *)interstitial
{
    [_adClient logImpression];

    if (_prefetch) {
        [self prefetchAd];
    }

    if ([_delegate respondsToSelector:@selector(interstitialDidAppear:)]) {
        [_delegate interstitialDidAppear:self];
    }
}

- (void)interstitialViewControllerWillDismiss:(MNMRAIDInterstitialViewController *)interstitial
{
    _adReady = NO;

    if ([_delegate respondsToSelector:@selector(interstitialWillDismiss:)]) {
        [_delegate interstitialWillDismiss:self];
    }

    _adClient = nil;
    _mraidInterstitialViewController = nil;
}

- (void)interstitialViewControllerDidDismiss:(MNMRAIDInterstitialViewController *)interstitial
{
    if ([_delegate respondsToSelector:@selector(interstitialDidDismiss:)]) {
        [_delegate interstitialDidDismiss:self];
    }
}

- (void)interstitialViewControllerBridge:(MNMRAIDInterstitialViewController *)interstitial command:(NSString *)command arguments:(NSDictionary *)arguments
{
    if ([command isEqualToString:@"MNHideClose"]) {
        [[[interstitial mraidView] closeButton] setHidden:YES];
    } else if ([command isEqualToString:@"MNUnhideClose"]) {
        [[[interstitial mraidView] closeButton] setHidden:NO];
    }
}

- (void)showAdFromViewController:(UIViewController *)viewController
{
    if (_adReady) {
        [_mraidInterstitialViewController showFromViewController:viewController];
    }
}

- (void)showAd
{
    if (_adReady) {
        [_mraidInterstitialViewController show];
    }
}

@end
