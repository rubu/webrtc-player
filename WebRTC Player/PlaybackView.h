#pragma once

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import <AppKit/AppKit.h>

#import <WebRTC/WebRTC.h>

@interface PlaybackView : NSView<NSComboBoxDataSource, RTCPeerConnectionDelegate>
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSButton *playButton;
@property (strong) IBOutlet NSView *contentView;
@property (weak) IBOutlet AVPlayerView *player;
@property (weak) IBOutlet NSComboBox *signallingPluginComboBox;

- (IBAction)play:(NSButton*)sender;

@end
