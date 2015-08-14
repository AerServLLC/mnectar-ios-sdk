#import <UIKit/UIKit.h>

@class MNRewardable;
@class MNReward;

@protocol MNRewardableDelegate <NSObject>

@optional
- (void)rewardableDidLoad:(MNRewardable *)rewardable;
- (void)rewardableDidFail:(MNRewardable *)rewardable;
- (void)rewardableWillAppear:(MNRewardable *)rewardable;
- (void)rewardableWillDismiss:(MNRewardable *)rewardable;
- (void)rewardableShouldRewardUser:(MNRewardable *)rewardable reward:(MNReward *)reward;

@end

@interface MNRewardable : NSObject

@property (nonatomic, weak) id<MNRewardableDelegate> delegate;

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
