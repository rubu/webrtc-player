#import "InfinivizSignallingPlugin.h"
#import "Log.h"

@implementation InfinivizSignallingPlugin
{
    NSURLSession *_urlSession;
    NSURL* _streamUrl;
    NSURL* _apiUrl;
    NSString* _sessionId;
}
- (instancetype)initWithAttributes:(NSDictionary*)attributes
                 completionHandler:(CreateSignallingPluginCompletionHandler)completionHandler
{
    self = [super init];
    
    if (self)
    {
        _urlSession = [NSURLSession sharedSession];
        _streamUrl = [attributes valueForKey:@"url"];
        _apiUrl = [[_streamUrl URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];
        completionHandler(self, nil);
    }
    return self;
}

- (void)getOfferWithCompletionHandler:(SdpOfferCompletionHandler)completionHandler
{
    NSURL *offerUrl = [_streamUrl URLByAppendingPathComponent:@"offer"];
    DDLogInfo(@"Attemtping to obtain remote offer from url %@", offerUrl.absoluteString);
    NSURLSessionDataTask *task = [_urlSession dataTaskWithURL:[_streamUrl URLByAppendingPathComponent:@"offer"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        if (response && [response class] == [NSHTTPURLResponse class])
        {
            NSHTTPURLResponse *httpResponse = response;
            if (httpResponse.statusCode == 200)
            {
                NSMutableDictionary *offer = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                _sessionId = [offer valueForKey:@"sessionId"];
                completionHandler(offer);
            }
            else
            {
                DDLogError(@"GET %@ failed with %d", offerUrl.absoluteString, httpResponse.statusCode);
            }
        }
    }];
    [task resume];
}

- (void)setAnswer:(NSString*)sdp completionHandler:(SdpAnswerCompletionHandler)completionHandler;
{
    if (sdp)
    {
        NSURL *answerUrl = [[[_apiUrl URLByAppendingPathComponent:@"webrtc-sessions"] URLByAppendingPathComponent:_sessionId] URLByAppendingPathComponent:@"answer"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:answerUrl];
        request.HTTPMethod = @"POST";
        NSMutableDictionary<NSString*, NSString*> *requestBody = [NSMutableDictionary dictionary];
        [requestBody setValue:sdp forKey:@"sdp"];
        [requestBody setValue:_sessionId forKey:@"sessionId"];
        [requestBody setValue:@"answer" forKey:@"type"];
        NSError *error;
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&error];
        if (error == nil)
        {
            DDLogInfo(@"Attemtping to send local answer to url %@", answerUrl.absoluteString);
            NSURLSessionDataTask *task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
            {
                if (response && [response class] == [NSHTTPURLResponse class])
                {
                    NSHTTPURLResponse *httpResponse = response;
                    if (httpResponse.statusCode == 200)
                    {
                        completionHandler();
                    }
                    else
                    {
                        DDLogError(@"POST %@ failed with %d", answerUrl.absoluteString, httpResponse.statusCode);
                    }
                }
            }];
            [task resume];
        }
    }
}


- (void)addIceCandiate:(NSDictionary*)candidate
{
    if (candidate)
    {
        NSURL *iceCandidateUrl = [[[_apiUrl URLByAppendingPathComponent:@"webrtc-sessions"] URLByAppendingPathComponent:_sessionId] URLByAppendingPathComponent:@"ice-candidate"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:iceCandidateUrl];
        request.HTTPMethod = @"POST";
        NSMutableDictionary<NSString*, NSString*> *requestBody = [NSMutableDictionary dictionary];
        NSError *error;
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:candidate options:0 error:&error];
        if (error == nil)
        {
            DDLogInfo(@"Attemtping to send local ice candidate to url %@", iceCandidateUrl.absoluteString);
            NSURLSessionDataTask *task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
            {
                if (response && [response class] == [NSHTTPURLResponse class])
                {
                    NSHTTPURLResponse *httpResponse = response;
                    if (httpResponse.statusCode != 200 && httpResponse.statusCode != 204)
                    {
                        DDLogError(@"POST %@ failed with %d", iceCandidateUrl.absoluteString, httpResponse.statusCode);
                    }
                }
            }];
            [task resume];
        }
    }
}

@end
