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

-(void)addLine:(NSString*)line
{
    dispatch_async(dispatch_get_main_queue(),^
    {
        NSDictionary *attributes =
        @{
            NSForegroundColorAttributeName: NSColor.textColor
        };
        [[self textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:attributes]];
    });
}
@end
