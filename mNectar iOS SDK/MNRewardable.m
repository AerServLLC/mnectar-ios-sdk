//
//  Copyright (c) 2015 mNectar, Inc  all rights reserved
//

#import "MNRewardable.h"
#import "MNMRAIDInterstitialViewController.h"
#import "MNAdClient.h"

@interface MNRewardable () <MNMRAIDInterstitialViewControllerDelegate>

@property (nonatomic, strong) MNMRAIDInterstitialViewController *mraidInterstitialViewController;
@property (nonatomic, strong) MNAdClient *adClient;

@end

static NSMutableDictionary *rewardables = nil;

@implementation MNRewardable

+ (instancetype)rewardableForAdUnitId:(NSString *)adUnitId
{
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        rewardables = [[NSMutableDictionary alloc] init];
    });

    if (![rewardables objectForKey:adUnitId]) {
        [rewardables setObject:[[[self class] alloc] initWithAdUnitId:adUnitId] forKey:adUnitId];
    }

    return [rewardables objectForKey:adUnitId];
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

    if ([_delegate respondsToSelector:@selector(rewardableDidLoad:)]) {
        [_delegate rewardableDidLoad:self];
    }
}
- (void)interstitialViewControllerDidFail
{
    _adReady = NO;

    _mraidInterstitialViewController = nil;

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
    _adReady = NO;

    if ([_delegate respondsToSelector:@selector(rewardableWillDismiss:)]) {
        [_delegate rewardableWillDismiss:self];
    }

    _mraidInterstitialViewController = nil;
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
    if (_mraidInterstitialViewController) {
        [_mraidInterstitialViewController showFromViewController:viewController];
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
