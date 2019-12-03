#pragma once

#import "SignallingPlugin.h"

#import <Foundation/Foundation.h>

#import <SocketRocket/SocketRocket.h>

NS_ASSUME_NONNULL_BEGIN

@interface OvenMediaEngineSignallingPlugin : NSObject<SignallingPlugin, SRWebSocketDelegate>

@end

NS_ASSUME_NONNULL_END
