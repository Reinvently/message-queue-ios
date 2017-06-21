//
//  PDAQueueMessageManager.h
//  Pedia
//
//  Created by aboyko on 11/3/16.
//  Copyright © 2016 Provectus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDAQueueCommand.h"
@protocol PDAMessageHandler;
typedef void (^PDAResponseBlock)(id __nullable result, NSError  * __nullable error);
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PDAMessageManagerState) {
    PDAMessageManagerStateSuspended,
    PDAMessageManagerStateRunnedIdle,           //has no message and wait next fire
    PDAMessageManagerStateRunnedProcessMessage, //process active message
    PDAMessageManagerStateRunnedIdleMessage,    //active msg has been processed and wait next fire
};
@interface PDAQueueMessageManager : NSObject
//@warning if messageProvider will set to nil manager will be suspended
@property (nonatomic, weak, nullable)                   id<PDAMessageHandler>  messageHandler;
//Check that manager was not suspended
@property (atomic, readonly, getter=isRunned)           BOOL                    runned;
//Current state
@property (atomic, readonly)                            PDAMessageManagerState  state;
//identificator for message queue
@property (nonatomic, readonly)                         NSString               *identificator;


// Class wich represents message. Must confirm to protocol PDAQueueCommand
// @warning By default PDAQueueCommand.
//          RAISE EXEPTION if Class dosen't conform to protocol PDAQueueCommand
@property (nonatomic, strong, null_resettable)          Class                   queueMessageClass;

/**
 *  Initializator
 *
 */
-(instancetype) initWithMessageHandler:(nullable id<PDAMessageHandler>)messageHandler;
-(instancetype) initWithIdentificator:(nullable NSString*)identificator
                       messageHandler:(nullable id<PDAMessageHandler>)messageHandler;
/**
 *  Stop processing messages.
 *  @warning Current message will be processed anyway. Async
 */
-(void) suspend;

/**
 *  Enabled processing message
 *  @warning messageProvider should be provided before this method was called. Async
 */
-(void) run;

/**
 *  Force fetch new message
 *  @warning Work only when state == PDAMessageManagerStateRunnedIdle. Async
 */
-(void) forceRequestMessage;
@end

@protocol PDAQueueCommand;
@protocol PDAMessageHandler <NSObject>
/**
 *  Confirm prev message and provide next from api layer. Async
 *  @param  messageId - already processed message. Could be nil
 *  @param  responseBlock - block which return NSDictionary with server response
 */
-(void) queueMessageManager:(PDAQueueMessageManager*)manager
       confirmMessageWithId:(nullable NSNumber*)messageId
         provideNextMessage:(nullable PDAResponseBlock)responseBlock;

/**
 *  Handle message from queue. Async
 *  @param  message - Message for Handle. By default is subclass of queueMessageClass
 *  @param  responseBlock - block which notify about ending of hanld message. Parameter result will be ignore in current implementation. Error tell for handler that message need reprocessed
 *  @see  property Class  queueMessageClass;
 */
-(void)  queueMessageManager:(PDAQueueMessageManager*)manager
               handleMessage:(id<PDAQueueCommand>)message
                  completion:(PDAResponseBlock)responseBlock;

/**
 Handle parse error
 
 @param manager Queue manager
 @param parseError Parse error
 @return Object. Return null if you don't want process error. Message queue will request again new command
 */
-(nullable id<PDAQueueCommand>) queueMessageManager:(PDAQueueMessageManager*)manager
                                  resolveParseError:(NSError*)parseError;

@end
NS_ASSUME_NONNULL_END
