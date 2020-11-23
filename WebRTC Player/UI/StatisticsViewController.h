#pragma once

#import <Cocoa/Cocoa.h>

@interface StatisticsViewController : NSViewController<NSOutlineViewDataSource>
@property (weak) IBOutlet NSOutlineView *outlineView;
@end
