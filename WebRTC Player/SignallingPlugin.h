#pragma once

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SignallingPlugin;

typedef void (^SdpOfferCompletionHandler)(NSDictionary<NSString *,NSString *> * _Nonnull);
typedef void (^SdpAnswerCompletionHandler)(void);
typedef void (^CreateSignallingPluginCompletionHandler)(NSObject<SignallingPlugin> * _Nullable, NSError * _Nullable);

@protocol SignallingPlugin <NSObject>
- (instancetype)initWithAttributes:(NSDictionary*)attributes completionHandler:(CreateSignallingPluginCompletionHandler)completionHandler;
- (void)getOfferWithCompletionHandler:(SdpOfferCompletionHandler)completionHandler;
- (void)setAnswer:(NSString*)sdp completionHandler:(SdpAnswerCompletionHandler)completionHandler;
- (void)addIceCandiate:(NSDictionary*)candidate;
@end

NS_ASSUME_NONNULL_END
