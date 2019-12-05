#import "PlaybackView.h"
#import "SignallingPluginFactory.h"
#import "Log.h"

NSString * const kSignallingPluginUserDefaultsKey = @"signallingPlugin";

@implementation PlaybackView
{
    NSArray<NSString*> *_plugins;
    RTCPeerConnection *_peerConnection;
    NSDictionary *_offer;
    NSObject<SignallingPlugin> *_signallingPlugin;
    RTCVideoTrack *_remoteVideoTrack;
}

-(void)initialize
{
    _plugins = [NSArray arrayWithObjects:@"Oven Media Engine", nil];
    BOOL viewLoaded = [[NSBundle mainBundle] loadNibNamed:@"PlaybackView" owner:self topLevelObjects:nil];
    NSAssert(viewLoaded, @"Failed to load PlaybackView");
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;
    [self initializeSignallingPluginComboBox];
}

-(void)initializeSignallingPluginComboBox
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger selectedPluginIndex = 0;
    if ([userDefaults doesContain:kSignallingPluginUserDefaultsKey])
    {
        id selectedPlugin = [userDefaults objectForKey:kSignallingPluginUserDefaultsKey];
        if ([selectedPlugin isKindOfClass:[NSString class]])
        {
            selectedPluginIndex = [_plugins indexOfObject:(NSString*)selectedPlugin];
            if (selectedPluginIndex == -1)
            {
                selectedPluginIndex = 0;
            }
        }
    }
    [_signallingPluginComboBox selectItemAtIndex:selectedPluginIndex];
}

-(PlaybackView*)initWithFrame:(CGRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self)
    {
        [self initialize];
    }

    return self;
}

-(PlaybackView*)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self)
    {
        [self initialize];
    }

    return self;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox
{
    if (comboBox == _signallingPluginComboBox)
    {
        return _plugins.count;
    }
    return 0;
}

- (void)reset
{
    _peerConnection = nil;
    _offer = nil;
}

- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index
{
    if (comboBox == _signallingPluginComboBox && index < _plugins.count)
    {
        return _plugins[index];
    }
    return nil;
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
    for (NSString *iceServer in [_signallingPlugin getIceServers])
    {
        [iceServers addObject:[[RTCIceServer alloc] initWithURLStrings:[NSArray arrayWithObject:iceServer]]];
    }
    rtcConfiguration.iceServers = iceServers;
    RTCPeerConnectionFactory *factory = [[RTCPeerConnectionFactory alloc] init];
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
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
    __unsafe_unretained typeof(self) weakSelf = self;
    [_peerConnection answerForConstraints:[self defaultAnswerConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error)
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

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    if (notification.object == _signallingPluginComboBox)
    {
        NSInteger selectedPluginIndex = [_signallingPluginComboBox indexOfSelectedItem];
        if (selectedPluginIndex >= 0 && selectedPluginIndex < _plugins.count)
        {
            [[NSUserDefaults standardUserDefaults] setObject:_plugins[selectedPluginIndex] forKey:kSignallingPluginUserDefaultsKey];
        }
    }
}

@end
