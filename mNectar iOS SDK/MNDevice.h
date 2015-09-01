//
//  Copyright (c) 2015 mNectar, Inc  all rights reserved
//

#import <UIKit/UIKit.h>

@interface MNDevice : NSObject

+ (MNDevice *)sharedDevice;

- (NSString *)udid;
- (BOOL)dnt;

- (NSString *)deviceName;

- (NSString *)connectionType;

- (NSString *)wwanCarrierName;
- (NSString *)wwanISOCountryCode;
- (NSString *)wwanMobileNetworkCode;
- (NSString *)wwanMobileCountryCode;

- (CGSize)screenSize;
- (CGFloat)screenScale;
- (NSString *)screenOrientation;

- (NSString *)timeZone;
- (NSString *)location;

@end
