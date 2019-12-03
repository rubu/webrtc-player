#import "SignallingPluginFactory.h"
#import "OvenMediaEngineSignallingPlugin.h"

@implementation SignallingPluginFactory

-(NSObject<SignallingPlugin>*)createSignallingPluginWithName:(NSString*)name
{
    if ([name isEqualToString:@"Oven Media Engine"])
    {
        return [[OvenMediaEngineSignallingPlugin alloc] init];
    }
    return nil;
}
@end
