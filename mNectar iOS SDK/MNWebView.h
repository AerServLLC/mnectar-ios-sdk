//
//  MNWebView.h
//  mNectar SDK Demo
//
//  Created by Ian Reiss on 12/9/15.
//  Copyright © 2015 mNectar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@class MNWebView;

@protocol MNWebViewDelegate <NSObject>

- (BOOL)webView:(MNWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request;
- (void)webView:(MNWebView *)webView didFailLoadWithError:(NSError *)error;

@end

@interface MNWebView : UIView

@property (nonatomic, weak) id<MNWebViewDelegate> delegate;

-(void) evaluateJavaScriptFromString:(NSString *)string;

- (void)loadHTML:(NSString *)html baseURL:(NSURL *)baseURL;
- (void)setFrame:(CGRect)frame;
- (void)setScalesPageToFit:(BOOL) scale;
- (void)loadRequest:(NSURLRequest *)request;

- (void)reload;
- (void)stopLoading;

- (void)goBack;
- (void)goForward;

- (BOOL) canGoBack;
- (BOOL) canGoForward;
- (BOOL) isLoading;

@end
