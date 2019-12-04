#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SdpOfferCallback)(NSDictionary<NSString *,NSString *> * _Nonnull);
typedef void (^SdpAnswerCallback)(void);

@protocol SignallingPlugin <NSObject>
- (void)getOfferFromUrl:(NSURL*) url withCompletion:(SdpOfferCallback)completion;
- (void)setAnswer:(NSString*)sdp withCompletion:(SdpAnswerCallback)completion;
@end

NS_ASSUME_NONNULL_END
