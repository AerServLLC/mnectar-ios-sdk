//
//  Copyright (c) 2015 mNectar, Inc  all rights reserved
//

#import "MNAdClient.h"
#import "AFNetworking.h"
#import "MNDevice.h"

#define MN_ENDPOINT "http://ads.mnectar.com/m/v1/ad"

NSString *URLEncodedString(NSString *string) {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
}

@interface MNAdClient ()

@property(nonatomic, strong) AFHTTPRequestOperationManager *requestManager;
@property(nonatomic, strong) NSString *adUnitId;
@property(nonatomic, strong) NSURL *impressionURL;

@end

@implementation MNAdClient

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
{
    if (self = [super init]) {
        _requestManager = [AFHTTPRequestOperationManager manager];
        [_requestManager setResponseSerializer:[AFHTTPResponseSerializer serializer]];

        _adUnitId = adUnitId;
    }
    
    return self;
}

- (NSURL *)adURL
{
    NSString *adUnitId = _adUnitId;
    NSString *udid = [[MNDevice sharedDevice] udid];
    NSString *dnt = [[MNDevice sharedDevice] dnt] ? @"1" : @"0";
    NSString *deviceName = [[MNDevice sharedDevice] deviceName];
    NSString *connectionType = [[MNDevice sharedDevice] connectionType];
    NSString *wwanCarrierName = [[MNDevice sharedDevice] wwanCarrierName];
    NSString *wwanISOCountryCode = [[MNDevice sharedDevice] wwanISOCountryCode];
    NSString *wwanMobileNetworkCode = [[MNDevice sharedDevice] wwanMobileNetworkCode];
    NSString *wwanMobileCountryCode = [[MNDevice sharedDevice] wwanMobileCountryCode];
    NSString *screenWidth = [NSString stringWithFormat:@"%.0f", [[MNDevice sharedDevice] screenSize].width];
    NSString *screenHeight = [NSString stringWithFormat:@"%.0f", [[MNDevice sharedDevice] screenSize].height];
    NSString *screenScale = [NSString stringWithFormat:@"%.1f", [[MNDevice sharedDevice] screenScale]];
    NSString *screenOrientation = [[MNDevice sharedDevice] screenOrientation];
    NSString *applicationBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *applicationVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *timeZone = [[MNDevice sharedDevice] timeZone];
    NSString *location = [[MNDevice sharedDevice] location];

    NSMutableString *url = [NSMutableString stringWithFormat:@"%@?mr=1", @MN_ENDPOINT];
    [url appendFormat:@"&id=%@", URLEncodedString(adUnitId)];
    [url appendFormat:@"&udid=%@", URLEncodedString(udid)];
    [url appendFormat:@"&dnt=%@", URLEncodedString(dnt)];
    [url appendFormat:@"&dn=%@", URLEncodedString(deviceName)];
    [url appendFormat:@"&ct=%@", URLEncodedString(connectionType)];
    [url appendFormat:@"&cn=%@", URLEncodedString(wwanCarrierName)];
    [url appendFormat:@"&iso=%@", URLEncodedString(wwanISOCountryCode)];
    [url appendFormat:@"&mnc=%@", URLEncodedString(wwanMobileNetworkCode)];
    [url appendFormat:@"&mcc=%@", URLEncodedString(wwanMobileCountryCode)];
    [url appendFormat:@"&w=%@", URLEncodedString(screenWidth)];
    [url appendFormat:@"&h=%@", URLEncodedString(screenHeight)];
    [url appendFormat:@"&sc=%@", URLEncodedString(screenScale)];
    [url appendFormat:@"&o=%@", URLEncodedString(screenOrientation)];
    [url appendFormat:@"&bundle=%@", URLEncodedString(applicationBundleIdentifier)];
    [url appendFormat:@"&av=%@", URLEncodedString(applicationVersion)];
    [url appendFormat:@"&z=%@", URLEncodedString(timeZone)];
    [url appendFormat:@"&ll=%@", URLEncodedString(location)];
    [url appendFormat:@"&%u", arc4random()];

    NSLog(@"%@", url);

    return [NSURL URLWithString:url];
}

- (void)requestAd:(void (^)(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error))handler
{
    NSURL *url = [self adURL];
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", [url scheme], [url host]]];

    NSMutableURLRequest *request = [[_requestManager requestSerializer] requestWithMethod:@"GET" URLString:[url absoluteString] parameters:nil error:nil];
    [request setValue:[[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"] forHTTPHeaderField:@"User-Agent"];

    AFHTTPRequestOperation *operation = [_requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, NSData *data) {
        NSError *error = nil;
        NSDictionary *headers = [[operation response] allHeaderFields];

        if ([headers[@"X-Adtype" ] isEqualToString:@"mraid"]) {
            _impressionURL = [NSURL URLWithString:headers[@"X-Imptracker"]];
        } else {
            error = [[NSError alloc] init];
        }

        handler(baseURL, [[operation response] statusCode], headers, data, error);
    } failure:^(AFHTTPRequestOperation * operation, NSError *error) {
        if ([[operation response] statusCode] != 302) {
            handler(baseURL, [[operation response] statusCode], [[operation response] allHeaderFields], nil, error);
        }
    }];

    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
        return request;
    }];
    
    [[[self requestManager] operationQueue] addOperation:operation];
}

- (void)logImpression
{
    if (_impressionURL) {
        NSMutableURLRequest *request = [[_requestManager requestSerializer] requestWithMethod:@"GET" URLString:[_impressionURL absoluteString] parameters:nil error:nil];

        AFHTTPRequestOperation *operation = [_requestManager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, NSData *data) {
        } failure:^(AFHTTPRequestOperation * operation, NSError *error) {
        }];

        [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
            return request;
        }];
        
        [[[self requestManager] operationQueue] addOperation:operation];
    }
}

@end
