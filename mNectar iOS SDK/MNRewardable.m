#import "MNRewardable.h"
#import "MNMRAIDInterstitialViewController.h"
#import "MNAdClient.h"

@interface MNRewardable () <MNMRAIDInterstitialViewControllerDelegate>

@property (nonatomic, strong) MNMRAIDInterstitialViewController *mraidInterstitialViewController;
@property (nonatomic, strong) MNAdClient *adClient;
@property (nonatomic, assign, getter=isAdLoading) BOOL adLoading;
@property (nonatomic, assign, getter=isAdLoaded) BOOL adLoaded;

@end

@implementation MNRewardable

@synthesize delegate = _delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
{
    if (self = [super init]) {
        _adClient = [[MNAdClient alloc] initWithAdUnitId:adUnitId];
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
    if ([_delegate respondsToSelector:@selector(rewardableDidLoad:)]) {
        [_delegate rewardableDidLoad:self];
    }
}
- (void)interstitialViewControllerDidFail
{
    _adLoaded = NO;

    if ([_delegate respondsToSelector:@selector(rewardableDidFail:)]) {
        [_delegate rewardableDidFail:self];
    }
}

- (void)interstitialViewControllerWillAppear
{
    if ([_delegate respondsToSelector:@selector(rewardableWillAppear:)]) {
        [_delegate rewardableWillAppear:self];
    }
}

- (void)interstitialViewControllerWillDismiss
{
    _adLoaded = NO;

    if ([_delegate respondsToSelector:@selector(rewardableWillDismiss:)]) {
        [_delegate rewardableWillDismiss:self];
    }
}

- (void)interstitialViewControllerCommand:(NSString *)command arguments:(NSDictionary *)arguments
{
    if ([command isEqualToString:@"MNHideClose"]) {
        [[[_mraidInterstitialViewController mraidView] closeButton] setHidden:YES];
    } else if ([command isEqualToString:@"MNUnhideClose"]) {
        [[[_mraidInterstitialViewController mraidView] closeButton] setHidden:NO];
    } else if ([command isEqualToString:@"MNReward"]) {
        if ([_delegate respondsToSelector:@selector(rewardableShouldRewardUser:reward:)]) {
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            NSString *type = [arguments objectForKey:@"type"] ? [arguments objectForKey:@"type"] : nil;
            NSNumber *amount = [arguments objectForKey:@"amount"] ? [numberFormatter numberFromString:[arguments objectForKey:@"amount"]] : [NSNumber numberWithInt:0];
            MNReward *reward = [[MNReward alloc] initWithType:type amount:amount];

            [_delegate rewardableShouldRewardUser:self reward:reward];
        }
    }
}

- (void)showAdFromViewController:(UIViewController *)viewController
{
    if (_adLoaded) {
        [_mraidInterstitialViewController showFromViewController:viewController];

        [[[_mraidInterstitialViewController mraidView] webView] setNeedsLayout];
    }
}

- (void)showAd
{
    [_mraidInterstitialViewController show];
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
