#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SdpOfferCallback)(NSDictionary<NSString *,NSString *> * _Nonnull);

@protocol SignallingPlugin <NSObject>
- (void)getOfferFromUrl:(NSURL*) url withCompletion:(SdpOfferCallback)completion;
@end

NS_ASSUME_NONNULL_END
