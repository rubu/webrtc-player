#pragma once

#import "MTKWebRTCVideoView.h"

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>

#import <WebRTC/WebRTC.h>

@interface PlaybackView : NSView<NSComboBoxDataSource, NSComboBoxDelegate, RTCPeerConnectionDelegate>
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSButton *playButton;
@property (strong) IBOutlet NSView *contentView;
@property (weak) IBOutlet NSComboBox *signallingPluginComboBox;
@property (weak) IBOutlet MTKWebRTCVideoView *videoView;

- (IBAction)play:(NSButton*)sender;

@end
