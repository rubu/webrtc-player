#import "PlaybackViewController.h"
#import "PlaybackView.h"

@interface PlaybackViewController ()

@end

@implementation PlaybackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _videoView.delegate = self;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

@end
