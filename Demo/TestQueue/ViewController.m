//
//  ViewController.m
//  TestQueue
//
//  Created by aboyko on 6/21/17.
//  Copyright © 2017 Reinvently. All rights reserved.
//

#import "ViewController.h"
#import "PDAQueueMessageManager.h"
@interface ViewController () <PDAMessageHandler>
@property (nonatomic, strong) PDAQueueMessageManager* manager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.manager = [[PDAQueueMessageManager alloc] initWithMessageHandler:self];
    [self.manager run];
}

- (void) queueMessageManager:(nonnull PDAQueueMessageManager *)manager
        confirmMessageWithId:(id)messageId
          provideNextMessage:(nullable PDAResponseBlock)responseBlock
{
    [self fetchNextMessage:responseBlock];
}

- (void) queueMessageManager:(nonnull PDAQueueMessageManager *)manager
               handleMessage:(nonnull id<PDAQueueCommand>)message
                  completion:(nonnull PDAResponseBlock)responseBlock
{
    responseBlock(nil,nil);
}

- (nullable id<PDAQueueCommand>) queueMessageManager:(nonnull PDAQueueMessageManager *)manager
                                   resolveParseError:(nonnull NSError *)parseError
{
    return nil;
}

#pragma mark - Help

-(void)fetchNextMessage:(PDAResponseBlock)responseBlock{
    NSURL *url = [NSURL URLWithString:@"http://devpediaq.webprv.com/api/command/next"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"27" forHTTPHeaderField:@"Version"];
    [request addValue:@"parent" forHTTPHeaderField:@"role"];
    [request addValue:@"android" forHTTPHeaderField:@"platform"];
    [request setHTTPMethod:@"POST"];
    NSDictionary *requestParams = @{@"token":@"5954ca09HEFE2rTcMO2AmuDgMu0pYhSd"};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:requestParams options:0 error:nil];
    
    [request setHTTPBody:postData];
    [[NSURLSession.sharedSession dataTaskWithRequest:request
                               completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
      {
          NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
          responseBlock(jsonResponse[@"command"],error);
      }] resume];


}
@end
