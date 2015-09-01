//
//  Copyright (c) 2015 mNectar, Inc  all rights reserved
//

#import <Foundation/Foundation.h>

@interface MNAdClient : NSObject

- (instancetype)initWithAdUnitId:(NSString *)adUnitId;

- (void)requestAd:(void (^)(NSURL *baseURL, NSInteger status, NSDictionary *headers, NSData *data, NSError *error))handler;
- (void)logImpression;

@end
