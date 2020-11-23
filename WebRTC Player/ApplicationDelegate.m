#import "ApplicationDelegate.h"
#import "StatisticsView.h"

@interface ApplicationDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet StatisticsView *statisticsView;
@end

@implementation ApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end
