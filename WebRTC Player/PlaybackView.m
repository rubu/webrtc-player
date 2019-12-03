#import "PlaybackView.h"
#import "SignallingPluginFactory.h"

NSString * const kSignallingPluginUserDefaultsKey = @"signallingPlugin";

@implementation PlaybackView
{
    NSArray<NSString*> *_plugins;
    RTCPeerConnection *_peerConnection;
    NSObject<SignallingPlugin> *_signallingPlugin;
}
-(void)initialize
{
    BOOL viewLoaded = [[NSBundle mainBundle] loadNibNamed:@"PlaybackView" owner:self topLevelObjects:nil];
    NSAssert(viewLoaded, @"Failed to load PlaybackView");
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;
    _plugins = [NSArray arrayWithObjects:@"Oven Media Engine", nil];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger selectedPlugin = 0;
    if ([userDefaults doesContain:kSignallingPluginUserDefaultsKey])
    {
        selectedPlugin = [userDefaults integerForKey:kSignallingPluginUserDefaultsKey];
    }
    [_signallingPluginComboBox selectItemAtIndex:selectedPlugin];
}

-(PlaybackView*)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
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
                    _signallingPlugin = [[[SignallingPluginFactory alloc] init] createSignallingPluginWithName:signallingPluginName];
                    if (_signallingPlugin)
                    {
                        [_signallingPlugin getOfferFromUrl:url withCompletion:^(NSDictionary<NSString *,NSString *> * offer) {
                            RTCConfiguration *rtcConfiguration = [[RTCConfiguration alloc] init];
                            RTCPeerConnectionFactory *factory = [[RTCPeerConnectionFactory alloc] init];
                            RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
                            self->_peerConnection = [factory peerConnectionWithConfiguration:rtcConfiguration constraints:constraints delegate:self];
                        }];
                    }
                }
            }
        }
    }
}

/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didChangeSignalingState:(RTCSignalingState)stateChanged
{
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream
{
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
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
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

@end
