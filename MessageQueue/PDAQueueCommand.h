//
//  PDAQueueCommand.h
//  Pedia
//
//  Created by Boyko Andrey on 1/17/15.
//  Copyright (c) 2015 Provectus. All rights reserved.
//
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol PDAQueueCommand <NSObject>

/**
 Message type
 */
@property(nonatomic, readonly, copy) NSNumber *type;


/**
 Nothing changes
 */
@property(nonatomic, readonly) BOOL isEmptyCommand;

/**
 Delay to the next message fetch
 */
@property(nonatomic, readonly) NSTimeInterval delay;

/**
 Message id
 */
@property(nonatomic, readonly, nullable) id messageId;

/**
 Timestamp
 */
@property(nonatomic, readonly, nullable) NSDate *timeAdd;

/**
 Additional info
 */
@property(nonatomic, readonly, nullable) NSDictionary *userInfo;


/**
 Fabric method which creates new instance of command.
 Can be used  by clients for creating different classes for different commands 
 
 @param jsonDict JSON which would be map into class
 @param error Parsing error
 @return new instance
 */
+ (nullable id <PDAQueueCommand>)modelObjectFromJSON:(nonnull NSDictionary *)jsonDict error:(NSError **)error;
@end


@interface PDAQueueCommand : NSObject <PDAQueueCommand>
@end

NS_ASSUME_NONNULL_END
