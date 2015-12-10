//
//  MNWebView.m
//  mNectar SDK Demo
//
//  Created by Ian Reiss on 12/9/15.
//  Copyright © 2015 mNectar. All rights reserved.
//

#import "MNWebView.h"

@interface MNWebView() <UIWebViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) UIWebView *oldWebView;
@property (nonatomic, strong) WKWebView *webView;

@end

@implementation MNWebView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([WKWebView class]) {
            NSLog(@"using webkit");
            WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
            [config setAllowsInlineMediaPlayback:YES];
            [config setMediaPlaybackRequiresUserAction:NO];
            _webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
            [[_webView scrollView] setScrollEnabled:NO];
            [_webView setBackgroundColor:[UIColor clearColor]];
            [_webView setOpaque:NO];
            
            [_webView setNavigationDelegate:self];
            [self addSubview:_webView];
        }
        else
        {
            NSLog(@"not using webkit");            
            _oldWebView = [[UIWebView alloc] initWithFrame:frame];
            [[_oldWebView scrollView] setScrollEnabled:NO];
            [_oldWebView setBackgroundColor:[UIColor clearColor]];
            [_oldWebView setOpaque:NO];
            [_oldWebView setAllowsInlineMediaPlayback:YES];
            [_oldWebView setMediaPlaybackRequiresUserAction:NO];
            [_oldWebView setDelegate:self];
            [self addSubview:_oldWebView];
        }
    }
    return self;
}

- (void)setScalesPageToFit:(BOOL) scale
{
    if ([WKWebView class]);
    else [_oldWebView setScalesPageToFit:scale];
}


-(void) evaluateJavaScriptFromString:(NSString *)string
{

    if ([WKWebView class]) {
        
        [_webView evaluateJavaScript:string completionHandler:nil];
    }
    else{
        [_oldWebView stringByEvaluatingJavaScriptFromString:string];
    }
}

- (void)loadHTML:(NSString *)html baseURL:(NSURL *)baseURL
{
    if ([WKWebView class]) {
        [_webView loadHTMLString:html baseURL:baseURL];
    }else [_oldWebView loadHTMLString:html baseURL:baseURL];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if ([WKWebView class]) {
        [_webView setFrame:frame];
    }
    else
    {
        [_oldWebView setFrame:frame];
    }

}

#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_delegate webView:self didFailLoadWithError:error];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [_delegate webView:self shouldStartLoadWithRequest:request];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error{
    [_delegate webView:self didFailLoadWithError:error];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([_delegate webView:self shouldStartLoadWithRequest:navigationAction.request]) decisionHandler(WKNavigationActionPolicyAllow);
    else decisionHandler(WKNavigationActionPolicyCancel);
}

#pragma mark - generic webview methods

- (void)loadRequest:(NSURLRequest *)request
{
    if ([WKWebView class]) {
        [_webView loadRequest:request];
    }
    else [_oldWebView loadRequest:request];
}

- (void)reload
{
    if ([WKWebView class]) {
        [_webView reload];
    }
    else [_oldWebView reload];
}

- (void)stopLoading
{
    if ([WKWebView class]) {
        [_webView stopLoading];
    }
    else [_oldWebView stopLoading];
}

- (void)goBack
{
    if ([WKWebView class]) {
        [_webView goBack];
    }
    else [_oldWebView goBack];
}

- (void)goForward
{
    if ([WKWebView class]) {
        [_webView goForward];
    }
    else [_oldWebView goForward];
}

- (BOOL) canGoBack
{
    if ([WKWebView class]) {
        return [_webView canGoBack];
    }
    else return [_oldWebView canGoBack];
}

- (BOOL) canGoForward
{
    if ([WKWebView class]) {
        return [_webView canGoForward];
    }
    else return [_oldWebView canGoForward];
}

- (BOOL) isLoading
{
    if ([WKWebView class]) {
        return [_webView isLoading];
    }
    else return [_oldWebView isLoading];
}



@end
