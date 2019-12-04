#import "OvenMediaEngineSignallingPlugin.h"
#import "Log.h"

@implementation OvenMediaEngineSignallingPlugin
{
    SdpOfferCallback _sdpOfferCallback;
    SdpAnswerCallback _sdpAnswerCallback;
    SRWebSocket *_webSocket;
    NSNumber* _id;
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

- (void)setAnswer:(NSString*)sdp withCompletion:(SdpAnswerCallback)completion;
{
    _sdpAnswerCallback = completion;
    NSDictionary *sdpDictionary =
    @{
        @"type": @"answer",
        @"sdp": sdp,
    };
    NSDictionary *command =
    @{
        @"command": @"answer",
        @"sdp": sdpDictionary,
        @"id": _id
    };
    NSError *error = nil;
    [_webSocket send:[NSJSONSerialization dataWithJSONObject:command options:0 error:&error]];
    _sdpAnswerCallback();
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    if ([message isKindOfClass:[NSString class]])
    {
        NSError *error = nil;
        id response = [NSJSONSerialization JSONObjectWithData:[(NSString*)message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (response)
        {
            NSString *command = [response objectForKey:@"command"];
            if ([command isEqualToString:@"offer"])
            {
                DDLogInfo(@"Obtained SDP offer:\n%@", response);
                id sdp = [response objectForKey:@"sdp"];
                id candidates = [response objectForKey:@"candidates"];
                id sessionId = [response objectForKey:@"id"];
                if ([sdp isKindOfClass:[NSDictionary class]]
                    && [candidates isKindOfClass:[NSArray class]]
                    && [sessionId isKindOfClass:[NSNumber class]])
                {
                    _id = (NSNumber*)sessionId;
                    NSDictionary<NSString*, NSString*> *offer = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                 [(NSDictionary*)sdp valueForKey:@"sdp"], @"sdp",
                                                                 (NSArray*)candidates, @"candidates", nil];
                    _sdpOfferCallback(offer);
                }
            }
            else if ([command isEqualToString:@"answer"])
            {
                _sdpAnswerCallback();
            }
            else
            {
                DDLogError(@"Received unexpected message in the WebSocket:\n%@", response);
            }
        }
        if (error)
        {
            DDLogError(@"%@", error);
        }
    }
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
        DDLogError(@"%@", error);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    
}
@end
