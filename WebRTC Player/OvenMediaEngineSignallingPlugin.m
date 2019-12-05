#import "OvenMediaEngineSignallingPlugin.h"
#import "Log.h"

@implementation OvenMediaEngineSignallingPlugin
{
    CreateSignallingPluginCompletionHandler _createSignallingPluginCompletionHandler;
    SdpOfferCompletionHandler _sdpOfferCompletionHandler;
    SdpAnswerCompletionHandler _sdpAnswerCompletionHandler;
    SRWebSocket *_webSocket;
    NSNumber* _id;
}

- (instancetype)initWithAttributes:(NSDictionary*)attributes
                 completionHandler:(CreateSignallingPluginCompletionHandler)completionHandler
{
    self = [super init];
    
    if (self)
    {
        _createSignallingPluginCompletionHandler = completionHandler;
        NSURL* url = [attributes valueForKey:@"url"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.allHTTPHeaderFields = @{ @"User-Agent": @"WebRTC Player"};
        _webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
        _webSocket.delegate = self;
        DDLogInfo(@"Opening Oven Media Engine WebSocket with url %@", _webSocket.url.absoluteURL);
        [_webSocket open];
    }
    return self;
}

- (void)getOfferWithCompletionHandler:(SdpOfferCompletionHandler)completionHandler
{
    _sdpOfferCompletionHandler = completionHandler;
    NSDictionary *command = @{
      @"command": @"request_offer",
    };
    NSError *error = nil;
    DDLogInfo(@"Sending request_offer to Oven Media Engine WebSocket with url %@", _webSocket.url.absoluteURL);
    [_webSocket send:[NSJSONSerialization dataWithJSONObject:command options:0 error:&error]];
}

- (void)setAnswer:(NSString*)sdp completionHandler:(SdpAnswerCompletionHandler)completionHandler;
{
    _sdpAnswerCompletionHandler = completionHandler;
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
    _sdpAnswerCompletionHandler();
}


- (void)addIceCandiate:(NSDictionary*)candidate
{
    NSDictionary *command =
    @{
        @"command": @"candidate",
        @"candidates": [NSArray arrayWithObject:candidate],
        @"id": _id
    };
    NSError *error = nil;
    [_webSocket send:[NSJSONSerialization dataWithJSONObject:command options:0 error:&error]];
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
                    _sdpOfferCompletionHandler(offer);
                }
            }
            else if ([command isEqualToString:@"answer"])
            {
                _sdpAnswerCompletionHandler();
            }
            else
            {
                DDLogError(@"Received unexpected message in Oven Media Engine WebSocket with url %@:\n%@", _webSocket.url.absoluteURL, response);
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
    DDLogInfo(@"Successfully opened Oven Media Engine WebSocket with url %@", webSocket.url.absoluteURL);
    _createSignallingPluginCompletionHandler(self, nil);
    _createSignallingPluginCompletionHandler = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    DDLogError(@"Failed to open opened Oven Media Engine WebSocket with url %@:\n%@", webSocket.url.absoluteURL, error);
    _createSignallingPluginCompletionHandler(nil, error ? error : [[NSError alloc] init]);
    _createSignallingPluginCompletionHandler = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    
}

- (NSArray<NSString*>*)getIceServers
{
    return [NSArray arrayWithObject:@"stun:stun.l.google.com:19302"];
}
@end
