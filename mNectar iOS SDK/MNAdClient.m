#import "MNAdClient.h"
#import "AFNetworking.h"
#import "MNDevice.h"

#define MN_ENDPOINT "http://ads.mnectar.com/m/v1/ad"

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

    NSString *udid = [[MNDevice sharedManager] udid];
    NSString *dnt = [[MNDevice sharedManager] dnt] ? @"1" : @"0";

    NSString *deviceName = [[MNDevice sharedManager] deviceName];

    NSString *connectionType = [[MNDevice sharedManager] connectionType];

    NSString *carrierName = nil;
    NSString *isoCountryCode = nil;

    NSString *mobileNetworkCode = nil;
    NSString *mobileCountryCode = nil;
    
    NSString *screenWidth = [NSString stringWithFormat:@"%.0f", [[MNDevice sharedManager] screenSize].width];
    NSString *screenHeight = [NSString stringWithFormat:@"%.0f", [[MNDevice sharedManager] screenSize].height];
    NSString *screenScale = [NSString stringWithFormat:@"%.1f", [[MNDevice sharedManager] screenScale]];
    NSString *screenOrientation = [[MNDevice sharedManager] screenOrientation];

    NSString *applicationBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *applicationVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    NSString *timeZone = [[MNDevice sharedManager] timeZone];
    NSString *location = nil;

    NSMutableString *url = [NSMutableString stringWithFormat:@"%@?mr=1", @MN_ENDPOINT];

    [url appendFormat:@"&id=%@", [adUnitId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [url appendFormat:@"&udid=ifa%%3A%@", [udid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [url appendFormat:@"&dnt=%@", [dnt stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [url appendFormat:@"&dn=%@", [deviceName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [url appendFormat:@"&ct=%@", [connectionType stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [url appendFormat:@"&w=%@", [screenWidth stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [url appendFormat:@"&h=%@", [screenHeight stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [url appendFormat:@"&sc=%@", [screenScale stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [url appendFormat:@"&o=%@", [screenOrientation stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [url appendFormat:@"&bundle=%@", [applicationBundleIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [url appendFormat:@"&av=%@", [applicationVersion stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [url appendFormat:@"&z=%@", [timeZone stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [url appendFormat:@"&%u", arc4random()];

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
