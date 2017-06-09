//
//  PDAQueueCommand.m
//  Pedia
//
//  Created by Boyko Andrey on 1/17/15.
//  Copyright (c) 2015 Provectus. All rights reserved.
//

#import "PDAQueueCommand.h"
NS_ASSUME_NONNULL_BEGIN
@interface PDAQueueCommand ()
@property (nonatomic, strong)    NSNumber* typeNumber;
@property (nonatomic, strong)    NSNumber* delayNumber;

@property (nonatomic, strong,  nullable) PDAObjectId           *messageId;
@property (nonatomic, strong,  nullable) NSDate                *timeAdd;
@property (nonatomic, strong,  nullable) NSDictionary          *userInfo;
@end


@implementation PDAQueueCommand
@dynamic type, delay;

PDASynthesizeNumberTransformer(messageId)
PDASynthesizeNumberTransformer(delayNumber)
PDASynthesizeNumberTransformer(typeNumber)
PDASynthesizeDateTransformer(timeAdd)


+(NSDictionary*) JSONKeyPathsByPropertyKey{
    return @{
             @"typeNumber"       : @"type",
             @"delayNumber"      : @"delay",
             @"userInfo"         : @"params",
             @"messageId"        : @"id",
             @"timeAdd"          : @"timeAdd"
             };
}
+(NSArray*)createKeys{
    return @[@"messageId"];
}

-(PDAQueueCommandType) type{
    return self.typeNumber.integerValue;
}

-(NSTimeInterval) delay{
    return self.delayNumber.doubleValue;
}
@end

NS_ASSUME_NONNULL_END
