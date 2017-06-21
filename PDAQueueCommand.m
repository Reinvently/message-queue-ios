//
//  PDAQueueCommand.m
//  Pedia
//
//  Created by Boyko Andrey on 1/17/15.
//  Copyright (c) 2015 Provectus. All rights reserved.
//

#import "PDAQueueCommand.h"
#define PDADynamicCast(object,classType) ([(object) isKindOfClass:[classType class]]?((classType*)object):nil)
static inline NSNumber* safeNumber(id number, NSNumber* defaultValue){
    if ([number isKindOfClass:[NSNumber class]]) {
        return number;
    }
    if (([number isKindOfClass:[NSString class]])||([number respondsToSelector:@selector(integerValue)])) {
        return @([number integerValue]);
    }
    return defaultValue;
}


NS_ASSUME_NONNULL_BEGIN
@interface PDAQueueCommand ()
@property (nonatomic, copy)    NSNumber* type;
@property (nonatomic, copy)    NSNumber* delayNumber;

@property (nonatomic, copy,  nullable) NSNumber           *messageId;
@property (nonatomic, copy,  nullable) NSDate                *timeAdd;
@property (nonatomic, copy,  nullable) NSDictionary          *userInfo;
@end


@implementation PDAQueueCommand
@dynamic delay, isEmptyCommand;

+(NSDictionary*) JSONKeyPathsByPropertyKey{
    return @{
             @"typeNumber"       : @"type",
             @"delayNumber"      : @"delay",
             @"userInfo"         : @"params",
             @"messageId"        : @"id",
             @"timeAdd"          : @"timeAdd"
             };
}

-(NSTimeInterval) delay{
    return self.delayNumber.doubleValue;
}

- (BOOL) isEmptyCommand{
    return (self.type.integerValue==0);
}

+ (nullable id<PDAQueueCommand>) modelObjectFromJSON:(nonnull NSDictionary *)jsonDict
                                                 key:(nullable NSString *)keyForMessageQueue
                                               error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSDictionary* object = keyForMessageQueue?jsonDict[keyForMessageQueue]:jsonDict;
    object = PDADynamicCast(object, NSDictionary);
    if (object==nil) {
        (*error) = [NSError errorWithDomain:@"" code:0 userInfo:nil];
        return nil;
    }
    NSNumber* typeNumber = safeNumber(object[@"type"], nil);
    NSNumber* delayNumber = safeNumber(object[@"delay"], nil);
    if ((typeNumber==nil)||(delayNumber==nil)) {
        (*error) = [NSError errorWithDomain:@"" code:0 userInfo:nil];
        return nil;
    }
    
    PDAQueueCommand *queueCommand = [PDAQueueCommand new];
    queueCommand.type = typeNumber;
    queueCommand.delayNumber = delayNumber;
    queueCommand.messageId = object[@"id"];
    queueCommand.userInfo = PDADynamicCast(object[@"params"], NSDictionary);
    queueCommand.timeAdd = PDADynamicCast(object[@"timeAdd"], NSDate);
    
    return queueCommand;
}
@end

NS_ASSUME_NONNULL_END


