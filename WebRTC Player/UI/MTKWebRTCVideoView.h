#pragma once

#import <MetalKit/MetalKit.h>
#import <WebRTC/WebRTC.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTKWebRTCVideoView : MTKView<RTCVideoRenderer>

- (void)render;

@end

NS_ASSUME_NONNULL_END
