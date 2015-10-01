#import "MNAdClient.h"
#import "MNConstants.h"
#import "AF2Networking.h"
#import "MNDevice.h"

NSString *URLEncodedString(NSString *string) {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
}

@interface MNAdClient ()

@property (nonatomic, strong) AF2HTTPRequestOperationManager *requestManager;
@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, strong) NSURL *impressionURL;

@end

@implementation MNAdClient

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
{
    if (self = [super init]) {
        _requestManager = [AF2HTTPRequestOperationManager manager];
        [_requestManager setResponseSerializer:[AF2HTTPResponseSerializer serializer]];

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

    NSMutableString *url = [NSMutableString stringWithFormat:@"%@://%@?v=%@&mr=1", MN_USE_HTTPS ? @"https" : @"http", @MN_ENDPOINT, @MN_VERSION];
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

    return [NSURL URLWithString:url];
}

- (void)requestAd:(void (^)(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error))handler
{
    NSURL *url = [self adURL];
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", [url scheme], [url host]]];

    NSLog(@"mnectar: requesting ad %@", url);

    NSMutableURLRequest *request = [[_requestManager requestSerializer] requestWithMethod:@"GET" URLString:[url absoluteString] parameters:nil error:nil];
    [request setValue:[[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"] forHTTPHeaderField:@"User-Agent"];

    AF2HTTPRequestOperation *operation = [_requestManager HTTPRequestOperationWithRequest:request success:^(AF2HTTPRequestOperation *operation, NSData *data) {
        NSError *error = nil;
        NSDictionary *headers = [[operation response] allHeaderFields];

        if ([headers[@"X-Adtype" ] isEqualToString:@"mraid"]) {
            _impressionURL = [NSURL URLWithString:headers[@"X-Imptracker"]];
        } else {
            error = [[NSError alloc] init];
        }

        handler(baseURL, [[operation response] statusCode], headers, data, error);
    } failure:^(AF2HTTPRequestOperation * operation, NSError *error) {
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
        NSLog(@"mnectar: logging impression %@", _impressionURL);

        NSMutableURLRequest *request = [[_requestManager requestSerializer] requestWithMethod:@"GET" URLString:[_impressionURL absoluteString] parameters:nil error:nil];

        AF2HTTPRequestOperation *operation = [_requestManager HTTPRequestOperationWithRequest:request success:^(AF2HTTPRequestOperation *operation, NSData *data) {
        } failure:^(AF2HTTPRequestOperation * operation, NSError *error) {
        }];

        [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
            return request;
        }];
        
        [[[self requestManager] operationQueue] addOperation:operation];
    }
}

@end
