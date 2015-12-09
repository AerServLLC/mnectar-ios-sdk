//
//  ViewController.m
//  mNectar SDK Demo
//
//  Created by Ian Reiss on 9/15/15.
//  Copyright (c) 2015 mNectar. All rights reserved.
//

#import "ViewController.h"
#import "MNConstants.h"


@interface ViewController()
@property (weak, nonatomic) IBOutlet UITextField *adUnitField;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property BOOL loaded;
@property MNRewardable *rewardable;
@property MNReward *reward;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loaded=false;
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)buttonPress:(id)sender {
    if (!self.loaded) {
        NSString *adUnit = [self.adUnitField text];
        
        NSMutableDictionary<NSString*, NSString*> *params = [NSMutableDictionary<NSString *, NSString *> new];
        [params setValue:@"3" forKey:@"pub_param0"];
        [params setValue:@"3" forKey:@"pub_param_adType"];
        [params setValue:@"1186012773" forKey:@"pub_param_uid"];

        
        self.rewardable = [MNRewardable rewardableForAdUnitId:adUnit parameters:params];
        [self.rewardable setDelegate:self];
        [self.button setEnabled:false];
        [self.rewardable loadAd];
        
    }
    else
    {
        [self.button setEnabled:false];
        [self.rewardable showAd];
        self.loaded=false;
    }
}

- (void)rewardableDidLoad:(MNRewardable *)rewardable;
{
    [self.button setEnabled:true];
    [self.button setTitle:@"Play Mini-Game" forState:UIControlStateNormal];
    [self.button setTitle:@"Playing..." forState:UIControlStateDisabled];
    self.loaded=true;
}
- (void)rewardableDidFail:(MNRewardable *)rewardable
{
    [self.button setEnabled:true];
    [self.button setTitle:@"Load Mini-Game" forState:UIControlStateNormal];
    [self.button setTitle:@"Loading..." forState:UIControlStateDisabled];
}
- (void)rewardableWillAppear:(MNRewardable *)rewardable
{

}
- (void)rewardableDidAppear:(MNRewardable *)rewardable
{
    
}
- (void)rewardableWillDismiss:(MNRewardable *)rewardable
{
    [self.button setEnabled:true];
    [self.button setTitle:@"Load Mini-Game" forState:UIControlStateNormal];
    [self.button setTitle:@"Loading..." forState:UIControlStateDisabled];
}
- (void)rewardableDidDismiss:(MNRewardable *)rewardable
{
    if(self.reward!=nil)
    {
        UIAlertController *ac =[UIAlertController alertControllerWithTitle:@"Congratulations!" message:[NSString stringWithFormat:@"You got %@ %@",self.reward.amount,self.reward.type] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
        [ac addAction:action];
        [self presentViewController:ac animated:YES completion:nil];
    }
    self.reward = nil;
}
- (void)rewardableShouldRewardUser:(MNRewardable *)rewardable reward:(MNReward *)reward
{
    self.reward =reward;
    NSLog(@"rewarded %@ %@", reward.type, reward.amount);
}


@end
