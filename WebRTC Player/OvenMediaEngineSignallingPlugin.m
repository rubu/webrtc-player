#import "OvenMediaEngineSignallingPlugin.h"

@implementation OvenMediaEngineSignallingPlugin
{
    SdpOfferCallback _sdpOfferCallback;
    SRWebSocket *_webSocket;
}

- (void)getOfferFromUrl:(nonnull NSURL *)url withCompletion:(SdpOfferCallback)completion
{
    _sdpOfferCallback = completion;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.allHTTPHeaderFields = @{ @"User-Agent": @"WebRTC Player"};
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
    _webSocket.delegate = self;
    [_webSocket open];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSDictionary<NSString*, NSString*> *offer = [NSDictionary dictionary];
    _sdpOfferCallback(offer);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSDictionary *command = @{
      @"command": @"request_offer",
    };
    NSError *error = nil;
    [_webSocket send:[NSJSONSerialization dataWithJSONObject:command options:0 error:&error]];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"%@", error);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    
}
@end
