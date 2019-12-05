#import "SignallingPluginFactory.h"
#import "OvenMediaEngineSignallingPlugin.h"

@implementation SignallingPluginFactory

-(NSObject<SignallingPlugin>*)createSignallingPluginWithName:(NSString*)name
                                                 attributes:(NSDictionary*)attributes
                                          completionHandler:(CreateSignallingPluginCompletionHandler)completionHandler
{
    if ([name isEqualToString:@"Oven Media Engine"])
    {
        return [[OvenMediaEngineSignallingPlugin alloc] initWithAttributes:attributes completionHandler:completionHandler];
    }
    return nil;
}
@end
