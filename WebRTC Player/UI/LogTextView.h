#pragma once

#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogTextView : NSTextView

-(void)addLine:(NSString*)line;

@end

NS_ASSUME_NONNULL_END
