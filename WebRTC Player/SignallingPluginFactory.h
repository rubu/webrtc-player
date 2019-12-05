#pragma once

#import "SignallingPlugin.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignallingPluginFactory : NSObject
- (NSObject<SignallingPlugin>*)createSignallingPluginWithName:(NSString*)name
                                                   attributes:(NSDictionary*)attributes
                                            completionHandler:(CreateSignallingPluginCompletionHandler)completionHandler;
                        
@end

NS_ASSUME_NONNULL_END
