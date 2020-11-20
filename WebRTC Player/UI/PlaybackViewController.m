#import "PlaybackViewController.h"
#import "SignallingPlugin.h"
#import "SignallingPluginFactory.h"
#import "Log.h"

NSString * const kSignallingPluginUserDefaultsKey = @"signallingPlugin";
NSString * const kSignallingPluginUrlUserDefaultsKey = @"signallingPluginUrl";

@interface PlaybackViewController ()

@end

@implementation PlaybackViewController
{
    RTCPeerConnection *_peerConnection;
    NSDictionary *_offer;
    NSObject<SignallingPlugin> *_signallingPlugin;
    RTCVideoTrack *_remoteVideoTrack;
    NSArray<NSString*> *_plugins;
}

- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        [self initialize];
    }
    return self;
}

-(void)initialize
{
    _plugins = [NSArray arrayWithObjects:@"Oven Media Engine", @"Infiniviz", @"Wowza", nil];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        [self initialize];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *selectedPlugin = [userDefaults stringForKey:kSignallingPluginUserDefaultsKey];
    NSInteger selectedPluginIndex = [_plugins indexOfObject:selectedPlugin];
    if (selectedPluginIndex == -1)
    {
        selectedPluginIndex = 0;
    }
    [_signallingPluginComboBox selectItemAtIndex:selectedPluginIndex];
    NSString *url = [userDefaults stringForKey:kSignallingPluginUrlUserDefaultsKey];
    if (url)
    {
        _urlTextField.stringValue = url;
    }
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

- (void)reset
{
    _peerConnection = nil;
    _offer = nil;
}

-(IBAction) play:(NSButton*)sender
{
    if (sender == _playButton)
    {
        NSString *urlString = _urlTextField.stringValue;
        if (urlString != nil && [urlString length])
        {
            NSURL *url = [NSURL URLWithString:urlString];
            if (url)
            {
                NSInteger selectedPluginIndex = _signallingPluginComboBox.indexOfSelectedItem;
                if (selectedPluginIndex >= 0 && selectedPluginIndex < _plugins.count)
                {
                    NSString *signallingPluginName = _plugins[_signallingPluginComboBox.indexOfSelectedItem];
                    NSDictionary *attributes =
                    @{
                        @"url": url
                    };
                    // This assignment is needed to keep the instance alive while the completion handler is pending
                    _signallingPlugin = [[[SignallingPluginFactory alloc] init] createSignallingPluginWithName:signallingPluginName
                                                                                                    attributes:attributes
                                                                                             completionHandler:^(NSObject<SignallingPlugin> *signallingPlugin, NSError *error)
                                         {
                        self->_signallingPlugin = signallingPlugin;
                        if (self->_signallingPlugin)
                        {
                            [self reset];
                            [self->_signallingPlugin getOfferWithCompletionHandler:^(NSDictionary* offer) {
                                [self didReceiveOffer:offer];
                            }];
                        }
                    }];
                }
            }
        }
    }
}

- (void)didReceiveOffer:(NSDictionary*)offer
{
    _offer = offer;
    RTCConfiguration *rtcConfiguration = [[RTCConfiguration alloc] init];
    NSMutableArray<RTCIceServer*> *iceServers = [NSMutableArray array];
    [iceServers addObject:[[RTCIceServer alloc] initWithURLStrings:[NSArray arrayWithObject:@"stun:stun.l.google.com:19302"]]];
    rtcConfiguration.iceServers = iceServers;
    RTCPeerConnectionFactory *factory = [[RTCPeerConnectionFactory alloc] init];
    NSDictionary<NSString*, NSString*> *mandatoryConstraints =
    @{
        kRTCMediaConstraintsOfferToReceiveVideo : kRTCMediaConstraintsValueFalse,
        kRTCMediaConstraintsOfferToReceiveAudio : kRTCMediaConstraintsValueFalse,
    };
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
    _peerConnection = [factory peerConnectionWithConfiguration:rtcConfiguration constraints:constraints delegate:self];
    NSString *sdp = [_offer objectForKey:@"sdp"];
    RTCSessionDescription *offerDescription = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:sdp];
    __unsafe_unretained typeof(self) weakSelf = self;
    [self->_peerConnection setRemoteDescription:offerDescription completionHandler:^(NSError *error)
     {
        [weakSelf didSetRemoteDescriptionWithError:error];
    }];
}

- (void)didSetRemoteDescriptionWithError:(NSError*)error
{
    if (error)
    {
        DDLogError(@"Failed to set remote description: %@", error);
        return;
    }
    __unsafe_unretained typeof(self) weakSelf = self;
    [_peerConnection answerForConstraints:[self defaultAnswerConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error)
     {
        if (error == nil && sdp)
        {
            [weakSelf->_signallingPlugin setAnswer:sdp.sdp completionHandler:^()
            {
                [weakSelf->_peerConnection setLocalDescription:sdp completionHandler:^(NSError *error)
                 {
                    if (error == nil)
                    {
                        NSArray<NSDictionary*> *candidates = [weakSelf->_offer objectForKey:@"candidates"];
                        for (NSDictionary *candidate in candidates)
                        {
                            id sdpMLineIndex = [candidate objectForKey:@"sdpMLineIndex"];
                            RTCIceCandidate *iceCandidate = [[RTCIceCandidate alloc] initWithSdp:[candidate objectForKey:@"candidate"] sdpMLineIndex:((NSNumber*)sdpMLineIndex).intValue sdpMid:nil];
                            if (iceCandidate)
                            {
                                [weakSelf->_peerConnection addIceCandidate:iceCandidate];
                            }
                            else
                            {
                                DDLogError(@"Failed to create ICE candidate");
                            }
                        }
                    }
                }];
            }];
        }
        else if (error)
        {
            DDLogError(@"WebRTC peer connection failed to provide and answer: %@", error);
        }
    }];
}

- (RTCMediaConstraints*)defaultAnswerConstraints
{
    NSDictionary *mandatoryConstraints = @{
        @"OfferToReceiveAudio" : @"true",
        @"OfferToReceiveVideo" : @"true"
    };
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}

/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged
{
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream
{
    if (stream.videoTracks && stream.videoTracks.count)
    {
        if (_remoteVideoTrack != nil)
        {
            [_remoteVideoTrack removeRenderer:_videoView];
        }
        _remoteVideoTrack = stream.videoTracks[0];
        [_remoteVideoTrack addRenderer:_videoView];
    }
}

/** Called when a remote peer closes a stream.
 *  This is not called when RTCSdpSemanticsUnifiedPlan is specified.
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream
{
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState
{
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState
{
    if (newState == RTCIceGatheringStateComplete)
    {
        DDLogInfo(@"ICE gathering complete");
    }
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
    NSDictionary *iceCandidate =
    @{
        @"candidate": candidate.sdp,
        @"sdpMLineIndex": [NSNumber numberWithInt:candidate.sdpMLineIndex],
        @"sdpMid": candidate.sdpMid
    };
    DDLogInfo(@"Sending ICE candidate:\n%@", iceCandidate);
    [_signallingPlugin addIceCandiate:iceCandidate];
}


/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel
{
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didAddReceiver:(RTCRtpReceiver *)rtpReceiver
       streams:(NSArray<RTCMediaStream *> *)mediaStreams
{
    rtpReceiver.delegate = self;
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didStartReceivingOnTransceiver:(RTCRtpTransceiver *)transceiver
{
}

- (void)rtpReceiver:(RTCRtpReceiver *)rtpReceiver
    didReceiveFirstPacketForMediaType:(RTCRtpMediaType)mediaType
{
    if (mediaType == RTCRtpMediaTypeAudio)
    {
        DDLogInfo(@"Got first audio packet");
    }
    else if (mediaType == RTCRtpMediaTypeVideo)
    {
        DDLogInfo(@"Got first video packet");
    }
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox
{
    if (comboBox == _signallingPluginComboBox)
    {
        return _plugins.count;
    }
    return 0;
}

- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index
{
    if (comboBox == _signallingPluginComboBox && index < _plugins.count)
    {
        return _plugins[index];
    }
    return nil;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    if (notification.object == _signallingPluginComboBox)
    {
        NSInteger selectedPluginIndex = [_signallingPluginComboBox indexOfSelectedItem];
        if (selectedPluginIndex >= 0 && selectedPluginIndex < _plugins.count)
        {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:_plugins[selectedPluginIndex] forKey:kSignallingPluginUserDefaultsKey];
            [userDefaults synchronize];
        }
    }
}

- (void)controlTextDidChange:(NSNotification *)notification
{
    if (notification.object == _urlTextField)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:_urlTextField.stringValue forKey:kSignallingPluginUrlUserDefaultsKey];
        [userDefaults synchronize];
    }
}


@end
