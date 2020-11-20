#import "PlaybackView.h"
#import "PlaybackViewController.h"

@implementation PlaybackView
{
    PlaybackViewController *_playbackViewController;
}
-(void)initialize
{
    _playbackViewController = [[PlaybackViewController alloc] initWithNibName:@"PlaybackViewController" bundle:[NSBundle mainBundle]];
    _playbackViewController.view.frame = self.bounds;
    [self addSubview:_playbackViewController.view];
}

-(instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        [self initialize];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        [self initialize];
    }
    return self;
}
@end
