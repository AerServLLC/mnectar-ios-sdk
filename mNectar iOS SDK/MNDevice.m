#import "MNDevice.h"
#import <AdSupport/ASIdentifierManager.h>
#import <sys/sysctl.h>
#import "AFNetworking.h"

static MNDevice *sharedManager = nil;

@implementation MNDevice

+ (MNDevice *)sharedManager
{
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        sharedManager = [[MNDevice alloc] init];
    });

    return sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {

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
    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi] ? @"2" : @"3";
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

@end
