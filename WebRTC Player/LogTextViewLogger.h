#pragma once

#import "Log.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LogTextView;

@interface LogTextViewLogger : DDAbstractLogger<DDLogger>
@property (nonatomic, weak) LogTextView *logTextView;

- (instancetype)initWithLogTextView:(LogTextView*)logTextView;

@end

NS_ASSUME_NONNULL_END
