#pragma once

#import "Log.h"

#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogTextView : NSTextView

-(void)addMessage:(DDLogMessage*)message;

@end

NS_ASSUME_NONNULL_END
