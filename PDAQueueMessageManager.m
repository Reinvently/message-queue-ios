//
//  PDAQueueMessageManager.m
//  Pedia
//
//  Created by aboyko on 11/3/16.
//  Copyright © 2016 Provectus. All rights reserved.
//

#import "PDAQueueMessageManager.h"
#import "PDAQueueCommand.h"
#import "EXTScope.h"
static const NSTimeInterval PDAQueueMessageManagerNowTime = 0.0;
static const NSTimeInterval PDAQueueMessageManagerDefaultIdleTime = 60.f;

//#define MESSAGE_LOG_ENABLED

#ifdef MESSAGE_LOG_ENABLED 
#define MESSAGE_LOG(desc, ...) \
   NSString *msg = [NSString stringWithFormat:(desc), ##__VA_ARGS__]; \
   NSLog(@"MESSAGE QUEUE %@", msg)
#else
#define MESSAGE_LOG(format, ...)
#endif

static inline void pda_dispatch_async_safe(dispatch_queue_t queue, dispatch_block_t block){
    if (queue==nil) {
        return;
    }
    dispatch_async(queue, block);
}

@interface PDAQueueMessageManager ()
@property (atomic, assign, getter=isActive)             BOOL                    active;
@property (getter=isIdle)                               BOOL                    idle;
@property (atomic, assign, getter=isProcessingMessage)  BOOL                    processingMessage;
@property (atomic, strong)                              id<PDAQueueCommand>     activeMessage;
@property (atomic, assign)                              NSTimeInterval          messageProcessingDelay;
@property (nonatomic, strong)                           NSString               *identificator;

@property (nonatomic,strong)                  dispatch_queue_t        queue;
@property (nonatomic,strong)                  dispatch_block_t        waitingBlock;
@end

@implementation PDAQueueMessageManager
@dynamic state, idle;
//
// MARK: -Init
//

-(instancetype) initWithIdentificator:(NSString *)identificator
                       messageHandler:(id<PDAMessageHandler>)messageHandler
{
    //don't remove duplicate
    self.identificator = identificator;
    self = [self init];
    if (self) {
        self.identificator = identificator;
        self.messageHandler = messageHandler;
    }
    return self;
}

-(instancetype) initWithMessageHandler:(id<PDAMessageHandler>) messageHandler {
    return [self initWithIdentificator:nil messageHandler:messageHandler];
}

-(instancetype) init {
    self = [super init];
    if (self) {
        NSString* defaultQueueId = @"care.q.messageHandler";
        NSString* queueId = self.identificator.length==0?defaultQueueId:[NSString stringWithFormat:@"%@.%@",defaultQueueId,self.identificator];
        self.queue = dispatch_queue_create([queueId UTF8String],DISPATCH_QUEUE_SERIAL);
        self.messageProcessingDelay = PDAQueueMessageManagerDefaultIdleTime;
        self.queueMessageClass = NULL;
    }
    return self;
}

-(void) dealloc {
    MESSAGE_LOG(@"Dealloc");
    self.queue = nil;
    [self suspendInternal];
}


//
// MARK: -Public
//
-(void) setMessageProvider:(id<PDAMessageHandler>)messageProvider{
    _messageHandler = messageProvider;
    MESSAGE_LOG(@"Change message provider");
    if (_messageHandler==nil) {
        [self suspend];
    }
}

/**
 *  Check that manager was not suspended
 */
-(BOOL) isRunned{
    return (self.state!=PDAMessageManagerStateSuspended);
}

-(BOOL) isIdle{
    PDAMessageManagerState state = self.state;
    return ((state==PDAMessageManagerStateRunnedIdle)||(state==PDAMessageManagerStateRunnedIdleMessage));
}
/**
 *  State
 *
 */
-(PDAMessageManagerState) state{
    @synchronized (self) {
        if ((self.isActive==NO)||(self.messageHandler==nil)) {
            return PDAMessageManagerStateSuspended;
        }
        if (self.isProcessingMessage) {
            return PDAMessageManagerStateRunnedProcessMessage;
        }
        return (self.activeMessage.type == PDAQueueCommandNone)?PDAMessageManagerStateRunnedIdle:PDAMessageManagerStateRunnedIdleMessage;
    }
}

/**
 *  Enabled processing message
 *  @warning messageProvider should be provided before this method was called. Async
 */
-(void) run{
    @weakify(self);
    dispatch_async(self.queue, ^{
        @strongify(self);
        MESSAGE_LOG(@"Try start");
        if (self.isRunned) {
            MESSAGE_LOG(@"Start failed. Already runned");
            return;
        }
        if (self.messageHandler==nil) {
            MESSAGE_LOG(@"Start failed. Handler is nil");
            return;
        }
        @synchronized (self) {
            self.active = YES;
            MESSAGE_LOG(@"Started");

        }
        [self sheduleNextFetchMessageAndConfirmPrev:nil afterDelay:PDAQueueMessageManagerNowTime];
    });
    
}

/**
 *  Force fetch new message
 *  @warning Work only when state == PDAMessageManagerStateRunnedIdle. Async
 */
-(void) forceRequestMessage{
    @weakify(self);
    dispatch_async(self.queue, ^{
        @strongify(self);
        MESSAGE_LOG(@"Try force update");
        if (self.isIdle) {
            [self sheduleNextFetchMessageAndConfirmPrev:self.activeMessage
                                             afterDelay:PDAQueueMessageManagerNowTime];
        }
    });
    
}

/**
 *  Stop processing messages.
 *  @warning Current message will be processed anyway. Async
 */
-(void) suspend{
    @weakify(self)
    dispatch_async(self.queue, ^{
        @strongify(self);
        [self suspendInternal];
    });
}

-(void) suspendInternal{
    @synchronized (self) {
        self.active = NO;
        self.processingMessage = NO;
        [self cancelSheduleOperation];
    }
}

-(void) setQueueMessageClass:(Class)queueMessageClass{
    if ((queueMessageClass!=NULL)&&([queueMessageClass conformsToProtocol:@protocol(PDAQueueCommand)])) {
        [NSException raise:@"Class don't conform protocol PDAQueueCommand" format:@""];
        queueMessageClass = NULL;
    }
    _queueMessageClass = queueMessageClass?:[PDAQueueCommand class];
}
//
// MARK: -Private
//
/**
 *  Prepare manager and fetch next message. 
 *  Optional - confirm prev message
 *  @param Message confirmation
 */
-(void) fetchNextMessageAndConfirmPrev:(nullable id<PDAQueueCommand>)message{
    MESSAGE_LOG(@"Try fetch");
    @synchronized (self) {
        if (self.isIdle==NO) {
            MESSAGE_LOG(@"Fetch failed. isIdle == NO");
            return;
        }
        MESSAGE_LOG(@"Start fetching");
        self.processingMessage = YES;
    }
    PNAWeakSelf;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        MESSAGE_LOG(@"Start fetching");
        [weakSelf.messageHandler queueMessageManager:weakSelf confirmMessageWithId:message.messageId
                                   provideNextMessage:^(NSDictionary* answer, NSError * error) {
            pda_dispatch_async_safe(weakSelf.queue, ^{
                MESSAGE_LOG(@"Did fetching %@ %@",answer, error);
                if (error) {
                    [weakSelf handleError:error prevMessage:message];
                }else{
                    [weakSelf prepareMessageForHandler:answer];
                }
            });
        }];
    });
    
    
}


/**
 *  Pepare message for handler
 *  @param Message confirmation
 */
-(void) prepareMessageForHandler:(NSDictionary*) message{
    if (self.state==PDAMessageManagerStateSuspended) {
        return;
    }
   
    //parse message
    NSError* parserError = nil;
    self.activeMessage = [self.queueMessageClass modelObjectFromJSON:message key:@"command" error:&parserError];
    if (parserError) {
        [NSException raise:@"Parser issue" format:@""];
    }else{
        if (self.activeMessage) {
            self.messageProcessingDelay = self.activeMessage.delay;
        }
    }
    
    
    PNAWeakSelf;
    //send message to handle
     dispatch_async(dispatch_get_main_queue(), ^{
         [weakSelf.messageHandler queueMessageManager:weakSelf
                                        handleMessage:weakSelf.activeMessage
                                           completion:^(id result, NSError *error)
          {
             pda_dispatch_async_safe(weakSelf.queue, ^{
                 [weakSelf finishProcessingMessage:weakSelf.activeMessage error:error];
             });
         }];
     });
}


-(void) finishProcessingMessage:(id<PDAQueueCommand>)message error:(NSError*)error{
    @synchronized (self) {
        self.processingMessage = NO;
    }
    
    if (error) {
        [self handleError:error];
        return;
    }
    
    id <PDAQueueCommand> confirmMessage = (message.type==PDAQueueCommandNone)?nil:message;
    [self sheduleNextFetchMessageAndConfirmPrev:confirmMessage afterDelay:message.delay];
}

//
// MARK: -When something went wrong
//
-(void) handleError:(nonnull NSError*)error{
    [self handleError:error prevMessage:nil];
}


-(void) handleError:(nonnull NSError*)error prevMessage:(id<PDAQueueCommand>)message{
    @synchronized (self) {
        self.processingMessage = NO;
    }
    [self sheduleNextFetchMessageAndConfirmPrev:message afterDelay:self.messageProcessingDelay];
}

//
// MARK: -Shedule
//
-(void) sheduleNextFetchMessageAndConfirmPrev:(id<PDAQueueCommand>)message afterDelay:(NSTimeInterval)delay{
    [self cancelSheduleOperation];
    if  (delay<=PDAQueueMessageManagerNowTime){
        [self fetchNextMessageAndConfirmPrev:message];
        return;
    }
    MESSAGE_LOG(@"Shedule next processing after %f",delay);
    @weakify(self);
    self.waitingBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
        @strongify(self);
        [self fetchNextMessageAndConfirmPrev:message];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), self.queue, self.waitingBlock);
}

-(void) cancelSheduleOperation{
    if (self.waitingBlock) {
        MESSAGE_LOG(@"Cancel last shedule");
        dispatch_block_cancel(self.waitingBlock);
        self.waitingBlock = nil;
    }
}
@end


