#pragma once

#import "MTKWebRTCVideoView.h"

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>
#import <WebRTC/WebRTC.h>

static NSString * const kActiveRTCPeerConnectionChangedNotification = @"activeRTCPeerConnectionChanged";

@interface PlaybackViewController : NSViewController<MTKViewDelegate, RTCPeerConnectionDelegate, RTCRtpReceiverDelegate, NSComboBoxDataSource, NSComboBoxDelegate, NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSComboBox *signallingPluginComboBox;
@property (weak) IBOutlet MTKWebRTCVideoView *videoView;

- (IBAction)play:(NSButton*)sender;

@end

