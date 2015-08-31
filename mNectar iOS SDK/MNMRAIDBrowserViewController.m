#import "MNMRAIDBrowserViewController.h"

#define MN_NAV_HEIGHT 45
#define MN_NAV_IMG_BACK_SIZE 28, 28
#define MN_NAV_IMG_BACK_NORMAL "MNMRAID.bundle/arrow_back_blue"
#define MN_NAV_IMG_BACK_DISABLED "MNMRAID.bundle/arrow_back_gray"
#define MN_NAV_IMG_FORWARD_SIZE 28, 28
#define MN_NAV_IMG_FORWARD_NORMAL "MNMRAID.bundle/arrow_forward_blue"
#define MN_NAV_IMG_FORWARD_DISABLED "MNMRAID.bundle/arrow_forward_gray"
#define MN_NAV_IMG_RELOAD_SIZE 28, 28
#define MN_NAV_IMG_RELOAD_NORMAL "MNMRAID.bundle/refresh_blue"
#define MN_NAV_IMG_CLOSE_SIZE 28, 28
#define MN_NAV_IMG_CLOSE_NORMAL "MNMRAID.bundle/close_blue"

@interface MNMRAIDBrowserViewController () <UIWebViewDelegate>

@property (nonatomic, assign) UIInterfaceOrientation orientation;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) UIButton *reloadButton;
@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation MNMRAIDBrowserViewController

- (instancetype)init
{
    if (self = [super init]) {
        _orientation = [[UIApplication sharedApplication] statusBarOrientation];

        CGRect screen = [[UIScreen mainScreen] bounds];

        [self setView:[[UIView alloc] initWithFrame:screen]];
        [[self view] setBackgroundColor:[UIColor clearColor]];
        [[self view] setOpaque:NO];

        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, screen.size.width, screen.size.height - MN_NAV_HEIGHT)];
        [_webView setScalesPageToFit:YES];
        [_webView setAllowsInlineMediaPlayback:YES];
        [_webView setMediaPlaybackRequiresUserAction:NO];
        [_webView setDelegate:self];
        [[self view] addSubview:_webView];

        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setFrame:CGRectMake(0, 0, MN_NAV_IMG_BACK_SIZE)];
        [_backButton setBackgroundImage:[UIImage imageNamed:@MN_NAV_IMG_BACK_NORMAL] forState:UIControlStateNormal];
        [_backButton setBackgroundImage:[UIImage imageNamed:@MN_NAV_IMG_BACK_DISABLED] forState:UIControlStateDisabled];
        [_backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];

        _forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_forwardButton setFrame:CGRectMake(0, 0, MN_NAV_IMG_FORWARD_SIZE)];
        [_forwardButton setBackgroundImage:[UIImage imageNamed:@MN_NAV_IMG_FORWARD_NORMAL] forState:UIControlStateNormal];
        [_forwardButton setBackgroundImage:[UIImage imageNamed:@MN_NAV_IMG_FORWARD_DISABLED] forState:UIControlStateDisabled];
        [_forwardButton addTarget:self action:@selector(forward) forControlEvents:UIControlEventTouchUpInside];

        _reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_reloadButton setFrame:CGRectMake(0, 0, MN_NAV_IMG_RELOAD_SIZE)];
        [_reloadButton setBackgroundImage:[UIImage imageNamed:@MN_NAV_IMG_RELOAD_NORMAL] forState:UIControlStateNormal];
        [_reloadButton addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];

        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setFrame:CGRectMake(0, 0, MN_NAV_IMG_CLOSE_SIZE)];
        [_closeButton setBackgroundImage:[UIImage imageNamed:@MN_NAV_IMG_CLOSE_NORMAL] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];

        UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_backButton];
        UIBarButtonItem *forwardButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_forwardButton];
        UIBarButtonItem *reloadButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_reloadButton];
        UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_closeButton];

        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, screen.size.height - MN_NAV_HEIGHT, screen.size.width, MN_NAV_HEIGHT)];
        [toolbar setItems:@[backButtonItem, forwardButtonItem, reloadButtonItem, flexItem, closeButtonItem]];
        [[self view] addSubview:toolbar];

        [self updateButtons];
    }

    return self;
}

- (void)updateButtons
{
    if ([_webView canGoBack]) {
        [_backButton setEnabled:YES];
    } else {
        [_backButton setEnabled:NO];
    }

    if ([_webView canGoForward]) {
        [_forwardButton setEnabled:YES];
    } else {
        [_forwardButton setEnabled:NO];
    }
}

- (void)back
{
    [_webView goBack];
}

- (void)forward
{
    [_webView goForward];
}

- (void)reload
{
    [_webView reload];
}

- (void)close
{
    [self dismissViewControllerAnimated:NO completion:^{}];
}

#pragma mark - UIViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask orientationMask = UIInterfaceOrientationMaskAll;
    NSArray *supportedInterfaceOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];

    if (UIInterfaceOrientationIsPortrait(_orientation)) {
        BOOL portraitSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationPortrait"];
        BOOL portraitUpsideDownSupported = [supportedInterfaceOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"];

        if (portraitSupported && portraitUpsideDownSupported) {
            orientationMask = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
        } else if (portraitSupported) {
            orientationMask = UIInterfaceOrientationMaskPortrait;
        } else if (portraitUpsideDownSupported) {
            orientationMask = UIInterfaceOrientationMaskPortraitUpsideDown;
        }
    } else if (UIInterfaceOrientationIsLandscape(_orientation)) {
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

    BOOL animationsEnabled = [UIView areAnimationsEnabled];

    [UIView setAnimationsEnabled:NO];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [UIView setAnimationsEnabled:animationsEnabled];
    }];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self updateButtons];
}

@end
