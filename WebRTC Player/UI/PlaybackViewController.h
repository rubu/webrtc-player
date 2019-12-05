#pragma once

#import "MTKWebRTCVideoView.h"

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlaybackViewController : NSViewController<MTKViewDelegate>
@property (weak) IBOutlet MTKWebRTCVideoView *videoView;
@end

NS_ASSUME_NONNULL_END
