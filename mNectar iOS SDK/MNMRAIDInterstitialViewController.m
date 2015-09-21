#import "MNMRAIDInterstitialViewController.h"
#import "AF2Networking.h"
#import "MNMRAIDBrowserViewController.h"
#import <StoreKit/StoreKit.h>

@interface MNSKStoreProductViewController : SKStoreProductViewController

@end

@implementation MNSKStoreProductViewController

- (BOOL)shouldAutorotate
{
    return NO;
}

@end

@interface MNMRAIDInterstitialViewController () <MNMRAIDViewDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, strong) AF2HTTPRequestOperationManager *requestManager;
@property (nonatomic, assign) BOOL currentAnimationEnabled;

@end

@implementation MNMRAIDInterstitialViewController

- (instancetype)init
{
    if (self = [super init]) {
        _orientation = [[UIApplication sharedApplication] statusBarOrientation];

        _mraidView = [[MNMRAIDView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [_mraidView setBackgroundColor:[UIColor clearColor]];
        [_mraidView setOpaque:NO];
        [_mraidView setPlacementType:MNMRAIDPlacementTypeInterstitial];
        [_mraidView setDelegate:self];
        [self setView:_mraidView];

        _requestManager = [AF2HTTPRequestOperationManager manager];
        [_requestManager setResponseSerializer:[AF2HTTPResponseSerializer serializer]];
    }

    return self;
}

- (void)loadHTML:(NSString *)html baseURL:(NSURL *)baseURL
{
    [[_mraidView webView] loadHTMLString:html baseURL:baseURL];
}

- (void)showFromViewController:(UIViewController *)viewController
{
    if ([self isBeingPresented] || [[self view] window]) {
        return;
    }

    if ([_delegate respondsToSelector:@selector(interstitialViewControllerWillAppear)]) {
        [_delegate interstitialViewControllerWillAppear];
    }

    if ([viewController isViewLoaded] && [[viewController view] window]) {
        [viewController presentViewController:self animated:NO completion:^{
            [_mraidView setIsViewable:YES];
        }];
    }
    
    if ([_delegate respondsToSelector:@selector(interstitialViewControllerDidAppear)]) {
        [_delegate interstitialViewControllerDidAppear];
    }
}

- (void)show
{
    UIViewController *viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];

    if ([viewController presentedViewController]) {
        viewController = [viewController presentedViewController];
    }

    [self showFromViewController:viewController];
}

#pragma mark - MNMRAIDViewDelegate

- (void)mraidDidLoad
{
    if ([_delegate respondsToSelector:@selector(interstitialViewControllerDidLoad)]) {
        [_delegate interstitialViewControllerDidLoad];
    }
}

- (void)mraidDidFail
{
    if ([_delegate respondsToSelector:@selector(interstitialViewControllerDidFail)]) {
        [_delegate interstitialViewControllerDidFail];
    }
}

- (void)mraidShouldClose
{
    if ([_delegate respondsToSelector:@selector(interstitialViewControllerWillDismiss)]) {
        [_delegate interstitialViewControllerWillDismiss];
    }

    [self dismissViewControllerAnimated:NO completion:^{}];
    
    if ([_delegate respondsToSelector:@selector(interstitialViewControllerDidDismiss)]) {
        [_delegate interstitialViewControllerDidDismiss];
    }
}

- (void)mraidShouldReorient
{
    UIViewController *presentingViewController = [self presentingViewController];

    if (presentingViewController) {
        __weak UIViewController *weakSelf = self;

        [self dismissViewControllerAnimated:NO completion:^{
            [presentingViewController presentViewController:weakSelf animated:NO completion:^{
            }];
        }];
    }
}

- (void)mraidShouldOpen:(NSURL *)url
{
    [_mraidView startLoading];

    NSLog(@"mnectar: opening %@", url);

    NSMutableURLRequest *request = [[_requestManager requestSerializer] requestWithMethod:@"GET" URLString:[url absoluteString] parameters:nil error:nil];

    AF2HTTPRequestOperation *operation = [_requestManager HTTPRequestOperationWithRequest:request success:^(AF2HTTPRequestOperation *operation, NSData *data) {
        MNMRAIDBrowserViewController *browserViewController = [[MNMRAIDBrowserViewController alloc] init];
        [[browserViewController webView] loadRequest:[operation request]];

        if ([self isViewLoaded] && [[self view] window]) {
            [self presentViewController:browserViewController animated:NO completion:^{}];
        }

        [_mraidView stopLoading];
    } failure:^(AF2HTTPRequestOperation *operation, NSError *error) {
        if ([[operation response] statusCode] != 302) {
            [_mraidView stopLoading];
        }
    }];

    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
        NSURL *url = [request URL];

        NSLog(@"mnectar: redirecting %@", url);

        NSString *scheme = [url scheme];
        NSString *host = [url host];
        NSString *path = [url path];

        if ([scheme isEqualToString:@"itms"] || [scheme isEqualToString:@"itms-apps"] || [host isEqualToString:@"itunes.apple.com"]) {
            if ([[path lastPathComponent] hasPrefix:@"id"]) {
                SKStoreProductViewController *productViewController = [[MNSKStoreProductViewController alloc] init];

                [productViewController setDelegate:self];
                [productViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:[[path lastPathComponent] substringFromIndex:2]} completionBlock:^(BOOL result, NSError *error) {
                    if (!error) {
                        _currentAnimationEnabled = [UIView areAnimationsEnabled];

                        [UIView setAnimationsEnabled:NO];

                        if ([self isViewLoaded] && [[self view] window]) {
                            [self presentViewController:productViewController animated:NO completion:^{
                                [UIView setAnimationsEnabled:_currentAnimationEnabled];
                            }];
                        } else {
                            [UIView setAnimationsEnabled:_currentAnimationEnabled];
                        }
                    } else {
                        [_mraidView stopLoading];
                    }
                }];
            }

            return nil;
        } else if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"] && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];

            [_mraidView stopLoading];

            return nil;
        }

        return request;
    }];

    [[[self requestManager] operationQueue] addOperation:operation];
}

- (void)mraidCommand:(NSString *)command arguments:(NSDictionary *)arguments
{
    if ([_delegate respondsToSelector:@selector(interstitialViewControllerCommand:arguments:)]) {
        [_delegate interstitialViewControllerCommand:command arguments:arguments];
    }
}

#pragma mark - UIViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask orientationMask = UIInterfaceOrientationMaskAll;

    MNMRAIDOrientation forceOrientation = [_mraidView forceOrientation];
    NSArray *supportedInterfaceOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];

    if ((forceOrientation == MNMRAIDOrientationPortrait) || (![_mraidView allowOrientationChange] && UIInterfaceOrientationIsPortrait(_orientation) && forceOrientation == MNMRAIDOrientationNone)) {
        BOOL portraitSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationPortrait"];
        BOOL portraitUpsideDownSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"];

        if (portraitSupported && portraitUpsideDownSupported) {
            orientationMask = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
        } else if (portraitSupported) {
            orientationMask = UIInterfaceOrientationMaskPortrait;
        } else if (portraitUpsideDownSupported) {
            orientationMask = UIInterfaceOrientationMaskPortraitUpsideDown;
        }
    } else if ((forceOrientation == MNMRAIDOrientationLandscape) || (![_mraidView allowOrientationChange] && UIInterfaceOrientationIsLandscape(_orientation) && forceOrientation == MNMRAIDOrientationNone)) {
        BOOL landscapeLeftSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"];
        BOOL landscapeRightSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"];

        if (landscapeLeftSupported && landscapeRightSupported) {
            orientationMask = UIInterfaceOrientationMaskLandscape;
        } else if (landscapeLeftSupported) {
            orientationMask = UIInterfaceOrientationMaskLandscapeLeft;
        } else if (landscapeRightSupported) {
            orientationMask = UIInterfaceOrientationMaskLandscapeRight;
        }
    }

    return orientationMask;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    _currentAnimationEnabled = [UIView areAnimationsEnabled];

    [UIView setAnimationsEnabled:NO];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [UIView setAnimationsEnabled:_currentAnimationEnabled];

        [_mraidView setMaxSize:[_mraidView frame].size];
        [_mraidView setScreenSize:[_mraidView frame].size];
        [_mraidView fireSizeChange];
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    _currentAnimationEnabled = [UIView areAnimationsEnabled];

    [UIView setAnimationsEnabled:NO];

    CGSize size = [[UIScreen mainScreen] bounds].size;

    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation) && size.width > size.height) {
        size = CGSizeMake(size.height, size.width);
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && size.height > size.width) {
        size = CGSizeMake(size.height, size.width);
    }

    [_mraidView setFrame:CGRectMake(0, 0, size.width, size.height)];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [UIView setAnimationsEnabled:_currentAnimationEnabled];

    CGSize size = [_mraidView frame].size;

    [_mraidView setMaxSize:size];
    [_mraidView setScreenSize:size];
    [_mraidView fireSizeChange];
}

#pragma mark - SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    _currentAnimationEnabled = [UIView areAnimationsEnabled];

    [UIView setAnimationsEnabled:NO];

    [viewController dismissViewControllerAnimated:NO completion:^{
        [UIView setAnimationsEnabled:_currentAnimationEnabled];
    }];

    [_mraidView stopLoading];
}

@end

