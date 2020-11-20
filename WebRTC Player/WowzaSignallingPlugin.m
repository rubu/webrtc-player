#import "WowzaSignallingPlugin.h"
#import "Log.h"

@implementation WowzaSignallingPlugin
{
    CreateSignallingPluginCompletionHandler _createSignallingPluginCompletionHandler;
    SdpOfferCompletionHandler _sdpOfferCompletionHandler;
    SdpAnswerCompletionHandler _sdpAnswerCompletionHandler;
    SRWebSocket *_webSocket;
    NSMutableDictionary *_streamInfo;
    NSMutableDictionary *_userData;
    NSMutableDictionary *_offer;
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
        _userData = [NSMutableDictionary dictionaryWithDictionary:@{
            @"param1": @"value1"
        }];
        _streamInfo = [NSMutableDictionary dictionaryWithDictionary:@{
            @"applicationName": @"webrtc",
            @"streamName": url.query,
            @"sessionId": @"[empty]"
        }];
        _webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
        _webSocket.delegate = self;
        DDLogInfo(@"Opening Wowza WebSocket with url %@", _webSocket.url.absoluteURL);
        [_webSocket open];
    }
    return self;
}

- (void)sendCommand:(NSDictionary *)command
{
    NSError *error = nil;
    NSData *commandData = [NSJSONSerialization dataWithJSONObject:command options:0 error:&error];
    NSString *commandString = [[NSString alloc] initWithData:commandData encoding:NSUTF8StringEncoding];
    DDLogInfo(@"Sending command %@ to Wowza WebSocket with url %@", commandString, _webSocket.url.absoluteURL);
    // It is imporant to send NSString not NSData, since that mimics the arraybuffer implementation in js
    [_webSocket send:commandString];
}

- (void)getOfferWithCompletionHandler:(SdpOfferCompletionHandler)completionHandler
{
    _sdpOfferCompletionHandler = completionHandler;
    NSDictionary *command = @{
      @"command": @"getOffer",
      @"direction": @"play",
      @"streamInfo": _streamInfo,
      @"userData": _userData
    };
    [self sendCommand:command];
}

- (void)setAnswer:(NSString*)sdp completionHandler:(SdpAnswerCompletionHandler)completionHandler;
{
    if (sdp)
    {
        _sdpAnswerCompletionHandler = completionHandler;
        NSDictionary *sdpDictionary =
        @{
            @"type": @"answer",
            @"sdp": sdp,
        };
        NSDictionary *command =
        @{
            @"command": @"sendResponse",
            @"direction": @"play",
            @"streamInfo": _streamInfo,
            @"sdp": sdpDictionary,
        };
        [self sendCommand:command];
    }
}


- (void)addIceCandiate:(NSDictionary*)candidate
{
    NSDictionary *command =
    @{
        @"command": @"candidate",
        @"candidates": [NSArray arrayWithObject:candidate],
    };
    [self sendCommand:command];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    if ([message isKindOfClass:[NSString class]])
    {
        if ([(NSString*)message hasPrefix:@"{MixedArray"])
        {
            // Wowza w/o plugins sends onFI st/sd with a MixedArray prefix
        }
        else
        {
            NSError *error = nil;
            id response = [NSJSONSerialization JSONObjectWithData:[(NSString*)message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            if (response)
            {
                NSNumber *status = [response objectForKey:@"status"];
                NSString *command = [response objectForKey:@"command"];
                if ([command isEqualToString:@"getOffer"] && [status unsignedShortValue] == 200)
                {
                    DDLogInfo(@"Obtained SDP offer:\n%@", response);
                    id sdp = [response objectForKey:@"sdp"];
                    id streamInfo = [response objectForKey:@"streamInfo"];
                    if (streamInfo && [streamInfo isKindOfClass:[NSDictionary class]])
                    {
                        [_streamInfo setValue:[(NSDictionary*)streamInfo valueForKey:@"sessionId"] forKey:@"sessionId"];
                    }
                    if ([sdp isKindOfClass:[NSDictionary class]])
                    {
                        // Fix Wowza Opus SDP sample rate issue
                        NSString *sdpString = [(NSDictionary*)sdp valueForKey:@"sdp"];
                        sdpString = [sdpString stringByReplacingOccurrencesOfString:@"OPUS/-1/2" withString:@"OPUS/48000/2"];
                        _offer = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                     sdpString, @"sdp", nil];
                        _sdpOfferCompletionHandler(_offer);
                    }
                }
                else if ([command isEqualToString:@"sendResponse"])
                {
                    NSArray *iceCandidates = [response objectForKey:@"iceCandidates"];
                    [_offer setValue:iceCandidates forKey:@"candidates"];
                    _sdpAnswerCompletionHandler();
                }
                else
                {
                    id st = [response objectForKey:@"st"], sd = [response objectForKey:@"sd"];
                    if ([st isKindOfClass:[NSString class]] && [sd isKindOfClass:[NSString class]])
                    {
                        
                    }
                    else
                    {
                        DDLogError(@"Received unexpected message in Wowza WebSocket with url %@:\n%@", _webSocket.url.absoluteURL, response);
                    }
                }
            }
            if (error)
            {
                DDLogError(@"%@", error);
            }
        }
    }
    else
    {
        int i = 3;
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    DDLogInfo(@"Successfully opened Wowza WebSocket with url %@", webSocket.url.absoluteURL);
    _createSignallingPluginCompletionHandler(self, nil);
    _createSignallingPluginCompletionHandler = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    DDLogError(@"Failed to open Wowza WebSocket with url %@:\n%@", webSocket.url.absoluteURL, error);
    _createSignallingPluginCompletionHandler(nil, error ? error : [[NSError alloc] init]);
    _createSignallingPluginCompletionHandler = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    DDLogError(@"Wowza WebSocket with url %@ did close connection: %@", webSocket.url.absoluteURL, reason);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    
}
@end
