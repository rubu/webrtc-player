#import "LogTextViewLogger.h"
#import "LogTextView.h"

@implementation LogTextViewLogger

- (instancetype)initWithLogTextView:(LogTextView*)logTextView
{
    self = [super init];
    if (self)
    {
        _logTextView = logTextView;
    }
    return self;
}

- (void)logMessage:(DDLogMessage *)logMessage
{
    if (logMessage->logMsg)
    {
        [_logTextView addLine:logMessage->logMsg];
    }
}
@end
