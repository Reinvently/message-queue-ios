//
//  NSError+Test.h
//  TestQueue
//
//  Created by aboyko on 6/30/17.
//  Copyright © 2017 Reinvently. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger,PDAQueueErrorCode) {
    PDAQueueErrorCodeNone = 0,
    PDAQueueErrorCodeParse
};
@interface NSError (Test)
+(NSError*) queueErrorWithDescription:(NSString*)description;
+(NSError*) queueErrorWithCode:(PDAQueueErrorCode)code description:(NSString*)description;
@end
