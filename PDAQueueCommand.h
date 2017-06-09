//
//  PDAQueueCommand.h
//  Pedia
//
//  Created by Boyko Andrey on 1/17/15.
//  Copyright (c) 2015 Provectus. All rights reserved.
//
@import Foundation;
#import <PediaCommon/PediaCommon.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger,PDAQueueCommandType) {
    PDAQueueCommandNone                     = 0,
    PDAQueueCommandUpdateRequest            = 1,
    PDAQueueCommandTransferRequest          = 2,
    PDAQueueCommandPaymentFailed            = 7,
    PDAQueueCommandPerformRequest           = 8,
    PDAQueueCommandUpdateResponsibleParty   = 3,
    PDAQueueCommandUpdateInsurance          = 5,
    PDAQueueCommandUpdateCarePhysician      = 6,
    PDAQueueCommandUpdateServiceArea        = 4,
    PDAQueueCommandUpdateUserStatus         = 9,
    PDAQueueCommandUpdateAppointment        = 11,
    PDAQueueCommandUserTwilioBadConnection  = 12,
    PDAQueueCommandUpdateUserInfo           = 13
};

@protocol PDAQueueCommand <NSObject>
//required properties
@property (nonatomic, readonly)           PDAQueueCommandType    type;
@property (nonatomic, readonly)           NSTimeInterval         delay;
//optional values
@property (nonatomic, readonly, nullable) PDAObjectId           *messageId;
@property (nonatomic, readonly, nullable) NSDate                *timeAdd;
@property (nonatomic, readonly, nullable) NSDictionary          *userInfo;
@end


@interface PDAQueueCommand : PDAModelObject<PDAQueueCommand>
@end
NS_ASSUME_NONNULL_END
