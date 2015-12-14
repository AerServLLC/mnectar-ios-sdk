#import "MNRewardable.h"
#import "MNConstants.h"
#import "MNMRAIDInterstitialViewController.h"
#import "MNAdClient.h"

@interface MNRewardable () <MNMRAIDInterstitialViewControllerDelegate>

@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, strong) MNMRAIDInterstitialViewController *mraidInterstitialViewController;
@property (nonatomic, strong) MNAdClient *adClient;
@property (nonatomic, assign) BOOL prefetchReady;
@property (nonatomic, strong) MNMRAIDInterstitialViewController *prefetchedMRAIDInterstitialViewController;
@property (nonatomic, strong) MNAdClient *prefetchedAdClient;

@end

static NSMutableDictionary *rewardables = nil;

@implementation MNRewardable

+ (instancetype)rewardableForAdUnitId:(NSString *)adUnitId parameters:(NSDictionary *)parameters
{
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        rewardables = [[NSMutableDictionary alloc] init];
    });

    if (![rewardables objectForKey:adUnitId]) {
        [rewardables setObject:[[[self class] alloc] initWithAdUnitId:adUnitId parameters:parameters] forKey:adUnitId];
    }

    return [rewardables objectForKey:adUnitId];
}

+ (instancetype)rewardableForAdUnitId:(NSString *)adUnitId
{
    return [MNRewardable rewardableForAdUnitId:adUnitId parameters:nil];
}

- (instancetype)initWithAdUnitId:(NSString *)adUnitId parameters:(NSDictionary *)parameters
{
    if (self = [super init]) {
        _adUnitId = adUnitId;
        _adReady = NO;
        _prefetch = MN_PREFETCH;
        _prefetchReady = NO;
        _parameters = parameters;

        if (_prefetch) {
            [self prefetchAd];
        }
    }

    return self;
}

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
{
    return [self initWithAdUnitId:adUnitId parameters:nil];
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
    NSMutableString *q = [[NSMutableString alloc] init];

    for (NSString *parameter in [_parameters allKeys]) {
        [q appendFormat:@"%@%@=%@", [q length] ? @"&" : @"", URLEncodedString(parameter), URLEncodedString(_parameters[parameter])];
    }

    if (_prefetch && !_prefetchedAdClient) {
        _prefetchedAdClient = [[MNAdClient alloc] initWithAdUnitId:_adUnitId];
        _prefetchedMRAIDInterstitialViewController = [[MNMRAIDInterstitialViewController alloc] initWithDelegate:self];

        [_prefetchedAdClient requestAd:^(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error) {
            if (data && !error) {
                [_prefetchedMRAIDInterstitialViewController loadHTML:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] baseURL:baseURL];
            } else {
                [self interstitialViewControllerDidFail:_prefetchedMRAIDInterstitialViewController];
            }
        } parameters:@{@"q" : q}];
    }
}

- (void)loadAd
{
    NSMutableString *q = [[NSMutableString alloc] init];

    for (NSString *parameter in [_parameters allKeys]) {
        [q appendFormat:@"%@%@=%@", [q length] ? @"&" : @"", URLEncodedString(parameter), URLEncodedString(_parameters[parameter])];
    }

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
        } parameters:@{@"q" : q}];
    }
}

#pragma mark - MNMRAIDInterstitialViewControllerDelegate

- (void)interstitialViewControllerDidLoad:(MNMRAIDInterstitialViewController *)interstitial
{
    if (interstitial == _prefetchedMRAIDInterstitialViewController) {
        _prefetchReady = YES;
    } else {
        _adReady = YES;

        if ([_delegate respondsToSelector:@selector(rewardableDidLoad:)]) {
            [_delegate rewardableDidLoad:self];
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

        if ([_delegate respondsToSelector:@selector(rewardableDidFail:)]) {
            [_delegate rewardableDidFail:self];
        }
    }
}

- (void)interstitialViewControllerWillAppear:(MNMRAIDInterstitialViewController *)interstitial
{
    if ([_delegate respondsToSelector:@selector(rewardableWillAppear:)]) {
        [_delegate rewardableWillAppear:self];
    }
}

- (void)interstitialViewControllerDidAppear:(MNMRAIDInterstitialViewController *)interstitial
{
    [_adClient logImpression];

    if (_prefetch) {
        [self prefetchAd];
    }

    if ([_delegate respondsToSelector:@selector(rewardableDidAppear:)]) {
        [_delegate rewardableDidAppear:self];
    }
}

- (void)interstitialViewControllerWillDismiss:(MNMRAIDInterstitialViewController *)interstitial
{
    _adReady = NO;

    if ([_delegate respondsToSelector:@selector(rewardableWillDismiss:)]) {
        [_delegate rewardableWillDismiss:self];
    }

    _adClient = nil;
    _mraidInterstitialViewController = nil;
}

- (void)interstitialViewControllerDidDismiss:(MNMRAIDInterstitialViewController *)interstitial
{
    if ([_delegate respondsToSelector:@selector(rewardableDidDismiss:)]) {
        [_delegate rewardableDidDismiss:self];
    }
}

- (void)interstitialViewControllerBridge:(MNMRAIDInterstitialViewController *)interstitial command:(NSString *)command arguments:(NSDictionary *)arguments
{
    if ([command isEqualToString:@"MNHideClose"]) {
        [[[interstitial mraidView] closeButton] setHidden:YES];
    } else if ([command isEqualToString:@"MNUnhideClose"]) {
        [[[interstitial mraidView] closeButton] setHidden:NO];
    } else if ([command isEqualToString:@"MNReward"]) {
        if ([_delegate respondsToSelector:@selector(rewardableShouldRewardUser:reward:)]) {
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            numberFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
            NSString *type = [arguments objectForKey:@"type"] ? [arguments objectForKey:@"type"] : nil;
            NSNumber *amount = [arguments objectForKey:@"amount"] ? [numberFormatter numberFromString:[arguments objectForKey:@"amount"]] : [NSNumber numberWithInt:0];
            MNReward *reward = [[MNReward alloc] initWithType:type amount:amount];

            [_delegate rewardableShouldRewardUser:self reward:reward];
        }
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

@implementation MNReward

- (MNReward *)initWithType:(NSString *)type amount:(NSNumber *)amount
{
    if (self = [self init]) {
        _type = type;
        _amount = amount;
    }

    return self;
}

- (MNReward *)initWithAmount:(NSNumber *)amount
{
    return [self initWithType:nil amount:amount];
}

@end
