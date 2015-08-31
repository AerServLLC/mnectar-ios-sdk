#import <UIKit/UIKit.h>

@interface MNDevice : NSObject

+ (MNDevice *)sharedManager;

- (NSString *)udid;
- (BOOL)dnt;

- (NSString *)deviceName;

- (NSString *)connectionType;

- (CGSize)screenSize;
- (CGFloat)screenScale;
- (NSString *)screenOrientation;

- (NSString *)timeZone;

@end
