//
//  NSError+Test.m
//  TestQueue
//
//  Created by aboyko on 6/30/17.
//  Copyright © 2017 Reinvently. All rights reserved.
//

#import "NSError+PDAQueue.h"
NSErrorDomain const PDAQueueErrorDomain = @"PDAQueueErrorDomain";

@implementation NSError (Test)
+ (NSError *)queueErrorWithDescription:(NSString *)description {
    return [self queueErrorWithCode:PDAQueueErrorCodeNone description:description];
}

+ (NSError *)queueErrorWithCode:(PDAQueueErrorCode)code description:(NSString *)description {
    NSDictionary *userInfo = nil;
    if (description) {
        userInfo = @{NSLocalizedDescriptionKey: description};
    }
    return [NSError errorWithDomain:PDAQueueErrorDomain code:code userInfo:userInfo];
}
@end
