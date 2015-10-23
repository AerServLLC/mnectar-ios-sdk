#import <Foundation/Foundation.h>

NSString *URLEncodedString(NSString *string);

@interface MNAdClient : NSObject

- (instancetype)initWithAdUnitId:(NSString *)adUnitId;

- (void)requestAd:(void (^)(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error))handler parameters:(NSDictionary *)parameters;
- (void)logImpression;

@end
