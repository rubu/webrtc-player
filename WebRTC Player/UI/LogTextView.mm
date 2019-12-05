#import "LogTextView.h"
#import "LogTextViewLogger.h"

@implementation LogTextView
LogTextViewLogger *_logger;

- (void)initialize
{
    _logger = [[LogTextViewLogger alloc] initWithLogTextView:self];
    [DDLog addLogger:_logger];
}

- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(nullable NSTextContainer *)container
{
    self = [super initWithFrame:frameRect textContainer:container];
    
    if (self)
    {
        [self initialize];
    }

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

    if (self)
    {
        [self initialize];
    }

    return self;
}

-(void)addMessage:(DDLogMessage*)message
{
    dispatch_async(dispatch_get_main_queue(),^
    {
        NSDate *currentTime = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd-MM HH:mm:ss"];
        NSString *timestamp = [dateFormatter stringFromDate: currentTime];
        const bool isError = message->logFlag & LOG_FLAG_ERROR;
        NSDictionary *attributes =
        @{
            NSForegroundColorAttributeName: isError ? NSColor.redColor : NSColor.textColor
        };
        NSString *line = [NSString stringWithFormat:@"%@ | %@\n", timestamp, message->logMsg];
        [[self textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:attributes]];
    });
}
@end
