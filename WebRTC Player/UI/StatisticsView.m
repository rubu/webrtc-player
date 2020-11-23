#import "StatisticsView.h"
#import "StatisticsViewController.h"

@implementation StatisticsView
{
    StatisticsViewController* _statisticsViewController;
}

-(void)initialize
{
    _statisticsViewController = [[StatisticsViewController alloc] initWithNibName:@"StatisticsViewController" bundle:[NSBundle mainBundle]];
    _statisticsViewController.view.frame = self.bounds;
    [self addSubview:_statisticsViewController.view];
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
