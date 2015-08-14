#import "MNMRAIDInterstitialViewController.h"
#import "AFNetworking.h"
#import "MNMRAIDBrowserViewController.h"
#import <StoreKit/StoreKit.h>

@interface MNMRAIDInterstitialViewController () <MNMRAIDViewDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, strong) AFHTTPRequestOperationManager *requestManager;

@end

@implementation MNMRAIDInterstitialViewController

- (instancetype)initWithHTML:(NSString *)html baseURL:(NSURL *)baseURL
{
    if (self = [super init]) {
        _orientation = [[UIApplication sharedApplication] statusBarOrientation];

        _mraidView = [[MNMRAIDView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [_mraidView setBackgroundColor:[UIColor clearColor]];
        [_mraidView setOpaque:NO];
        [_mraidView setPlacementType:MNMRAIDPlacementTypeInterstitial];
        [_mraidView setDelegate:self];
        [self setView:_mraidView];

        [[_mraidView webView] loadHTMLString:html baseURL:baseURL];

        _requestManager = [AFHTTPRequestOperationManager manager];
        [_requestManager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    }
    
    return self;
}

- (void)showFromViewController:(UIViewController *)viewController
{
    if ([_delegate respondsToSelector:@selector(interstitialViewControllerWillAppear)]) {
        [_delegate interstitialViewControllerWillAppear];
    }

    if ([viewController isViewLoaded] && [[viewController view] window]) {
        [viewController presentViewController:self animated:NO completion:^{
            [_mraidView setIsViewable:YES];
        }];
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
    [_mraidView expand:nil];

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
}

- (void)mraidShouldOpen:(NSURL *)url
{
    [_mraidView startLoading];

    NSMutableURLRequest *request = [[_requestManager requestSerializer] requestWithMethod:@"GET" URLString:[url absoluteString] parameters:nil error:nil];

    AFHTTPRequestOperation *operation = [_requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, NSData *data) {
        MNMRAIDBrowserViewController *browserViewController = [[MNMRAIDBrowserViewController alloc] init];
        [[browserViewController webView] loadRequest:[operation request]];

        if ([self isViewLoaded] && [[self view] window]) {
            [self presentViewController:browserViewController animated:NO completion:^{}];
        }

        [_mraidView stopLoading];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([[operation response] statusCode] != 302) {
            [_mraidView stopLoading];
        }
    }];

    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
        NSURL *url = [request URL];

        NSString *scheme = [url scheme];
        NSString *host = [url host];
        NSString *path = [url path];

        if ([scheme isEqualToString:@"itms"] || [scheme isEqualToString:@"itms-apps"] || [host isEqualToString:@"itunes.apple.com"]) {
            if ([[path lastPathComponent] hasPrefix:@"id"]) {
                SKStoreProductViewController *productViewController = [[SKStoreProductViewController alloc] init];

                [productViewController setDelegate:self];
                [productViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:[[path lastPathComponent] substringFromIndex:2]} completionBlock:^(BOOL result, NSError *error) {
                    if (!error) {
                        BOOL animationsEnabled = [UIView areAnimationsEnabled];

                        [UIView setAnimationsEnabled:NO];

                        if ([self isViewLoaded] && [[self view] window]) {
                            [self presentViewController:productViewController animated:NO completion:^{
                                [UIView setAnimationsEnabled:animationsEnabled];
                            }];
                        } else {
                            [UIView setAnimationsEnabled:animationsEnabled];
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
    MNMRAIDOrientation forceOrientation = [_mraidView forceOrientation];
    NSArray *supportedInterfaceOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];

    if ((forceOrientation == MNMRAIDOrientationPortrait) || (![_mraidView allowOrientationChange] && UIInterfaceOrientationIsPortrait(_orientation) && forceOrientation == MNMRAIDOrientationNone)) {
        BOOL portraitSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationPortrait"];
        BOOL portraitUpsideDownSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"];

        if (portraitSupported && portraitUpsideDownSupported) {
            NSLog(@"p + pu");
            return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
        } else if (portraitSupported) {
            NSLog(@"p");
            return UIInterfaceOrientationMaskPortrait;
        } else if (portraitUpsideDownSupported) {
            NSLog(@"pu");
            return UIInterfaceOrientationMaskPortraitUpsideDown;
        }
    } else if ((forceOrientation == MNMRAIDOrientationLandscape) || (![_mraidView allowOrientationChange] && UIInterfaceOrientationIsLandscape(_orientation) && forceOrientation == MNMRAIDOrientationNone)) {
        BOOL landscapeLeftSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"];
        BOOL landscapeRightSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"];

        if (landscapeLeftSupported && landscapeRightSupported) {
            NSLog(@"ll + lr");
            return UIInterfaceOrientationMaskLandscape;
        } else if (landscapeLeftSupported) {
            NSLog(@"ll");
            return UIInterfaceOrientationMaskLandscapeLeft;
        } else if (landscapeRightSupported) {
            NSLog(@"lr");
            return UIInterfaceOrientationMaskLandscapeRight;
        }
    }

    NSLog(@"all");
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    BOOL animationsEnabled = [UIView areAnimationsEnabled];

    [UIView setAnimationsEnabled:NO];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [UIView setAnimationsEnabled:animationsEnabled];

        [_mraidView setDefaultPosition:[_mraidView frame]];
        [_mraidView setCurrentPosition:[_mraidView frame]];
        [_mraidView fireSizeChange];
    }];
}

#pragma mark - SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    BOOL animationsEnabled = [UIView areAnimationsEnabled];

    [UIView setAnimationsEnabled:NO];

    [viewController dismissViewControllerAnimated:NO completion:^{
        [UIView setAnimationsEnabled:animationsEnabled];
    }];

    [_mraidView stopLoading];
}

@end
