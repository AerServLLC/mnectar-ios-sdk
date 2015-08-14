#import "MNAdClient.h"
#import "AFNetworking.h"
#import <AdSupport/ASIdentifierManager.h>
#import <sys/sysctl.h>

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
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *deviceName = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    // &cn=0&sc_a=2.0&ct=0&av=3.7.0&v=1&nv=1.0.0
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@?mr=1&frq=0&trg=0", @MN_ENDPOINT];
    [url appendFormat:@"&udid=ifa%%3A%@", [[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [url appendFormat:@"&dnt=%d", [[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled] ? 0 : 1];
    [url appendFormat:@"&dn=%@", [deviceName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [url appendFormat:@"&o=%@", UIInterfaceOrientationIsPortrait(orientation) ? @"p" : @"l"];
    [url appendFormat:@"&id=%@", [_adUnitId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [url appendFormat:@"&%u", arc4random()];

    return [NSURL URLWithString:url];
}

- (void)requestAd:(void (^)(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error))handler
{
    NSURL *url = [self adURL];
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", [url scheme], [url host]]];

    NSMutableURLRequest *request = [[_requestManager requestSerializer] requestWithMethod:@"GET" URLString:[url absoluteString] parameters:nil error:nil];

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
