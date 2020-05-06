#import "SignallingPluginFactory.h"
#import "OvenMediaEngineSignallingPlugin.h"
#import "InfinivizSignallingPlugin.h"

@implementation SignallingPluginFactory

-(NSObject<SignallingPlugin>*)createSignallingPluginWithName:(NSString*)name
                                                 attributes:(NSDictionary*)attributes
                                          completionHandler:(CreateSignallingPluginCompletionHandler)completionHandler
{
    if ([name isEqualToString:@"Oven Media Engine"])
    {
        return [[OvenMediaEngineSignallingPlugin alloc] initWithAttributes:attributes completionHandler:completionHandler];
    }
    else if ([name isEqualToString:@"Infiniviz"])
    {
        return [[InfinivizSignallingPlugin alloc] initWithAttributes:attributes completionHandler:completionHandler];
    }
    return nil;
}
@end
