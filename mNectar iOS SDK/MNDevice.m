#import "MNDevice.h"
#import <AdSupport/ASIdentifierManager.h>
#import <sys/sysctl.h>
#import "AF2Networking.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreLocation/CoreLocation.h>

static MNDevice *sharedDevice = nil;

@interface MNDevice ()

@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation MNDevice

+ (MNDevice *)sharedDevice
{
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        sharedDevice = [[MNDevice alloc] init];
    });

    return sharedDevice;
}

- (instancetype)init
{
    if (self = [super init]) {
        _networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        _locationManager = [[CLLocationManager alloc] init];

        if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
            [_locationManager startMonitoringSignificantLocationChanges];
        }

        [[AF2NetworkReachabilityManager sharedManager] startMonitoring];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }

    return self;
}

- (NSString *)udid
{
    return [NSString stringWithFormat:@"ifa:%@", [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]];
}

- (BOOL)dnt
{
    return ![[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled];
}

- (NSString *)deviceName
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);

    NSString *deviceName = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];

    free(machine);

    return deviceName;
}

- (NSString *)connectionType
{
    return [[AF2NetworkReachabilityManager sharedManager] isReachableViaWiFi] ? @"2" : @"3";
}

- (NSString *)wwanCarrierName
{
    NSString *wwanCarrierName = [[_networkInfo subscriberCellularProvider] carrierName];

    return wwanCarrierName ? wwanCarrierName : @"";
}

- (NSString *)wwanISOCountryCode
{
    NSString *wwanISOCountryCode = [[_networkInfo subscriberCellularProvider] isoCountryCode];

    return wwanISOCountryCode ? wwanISOCountryCode : @"";
}

- (NSString *)wwanMobileNetworkCode
{
    NSString *wwanMobileNetworkCode = [[_networkInfo subscriberCellularProvider] mobileNetworkCode];

    return wwanMobileNetworkCode ? wwanMobileNetworkCode : @"";
}

- (NSString *)wwanMobileCountryCode
{
    NSString *wwanMobileCountryCode = [[_networkInfo subscriberCellularProvider] mobileCountryCode];

    return wwanMobileCountryCode ? wwanMobileCountryCode : @"";
}

- (CGSize)screenSize
{
    return [[UIScreen mainScreen] bounds].size;
}

- (CGFloat)screenScale
{
    return [[UIScreen mainScreen] scale];
}

- (NSString *)screenOrientation
{
   return UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? @"p" : @"l";
}

- (NSString *)timeZone
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"Z"];

    return [dateFormatter stringFromDate:[NSDate date]];
}

- (NSString *)location
{
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        return [NSString stringWithFormat:@"%.3f,%.3f", [[_locationManager location] coordinate].latitude, [[_locationManager location] coordinate].longitude];
    }

    return @"";
}

#pragma mark - UIApplication notifications

- (void)willEnterForeground:(NSNotification *)notification
{
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        [_locationManager startMonitoringSignificantLocationChanges];
    }

    [[AF2NetworkReachabilityManager sharedManager] startMonitoring];
}

- (void)willResignActive:(NSNotification *)notification
{
    [_locationManager stopMonitoringSignificantLocationChanges];

    [[AF2NetworkReachabilityManager sharedManager] stopMonitoring];
}

@end
