Message Queue for iOS
=============================
INSTALLATION
------------
Add to your pod file 
```ruby
    source 'http://gitlab.provectus-it.com/reinvently/cocoapod-specs.git'
    pod 'MessageQueue'
```
QUICK START
-----------
You can use cocoapods command "try" for run DemoProject

Steps:
1. Add Reinvently Private repo to your CocoaPods installation

    ```ruby
    pod repo add reinvently-specs git@gitlab.provectus-it.com:reinvently/cocoapod-specs.git
    ```
2. Run "try" command

    ```ruby
    pod try MessageQueue
    ```
    
HOW TO USE
-----------
1. Initiate PDAQueueMessageManager 

    ```objective-c
    PDAQueueMessageManager *manager = [[PDAQueueMessageManager alloc] initWithMessageHandler:delegate];
    ```
2. Start manager

    ```objective-c
    [manager run];
    ```

3. Conform PDAMessageHandler
    
  3.1 Request message from server

    ```objective-c
    - (void) queueMessageManager:(nonnull PDAQueueMessageManager *)manager
               confirmMessageWithId:(id)messageId
                provideNextMessage:(nullable PDAResponseBlock)responseBlock
    {
        [self.api confirmMessageWithId:messageId requestNew: ^(NSData * data, NSError * error) {
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            responseBlock(jsonResponse[@"command"],error);
        }];
    }
    ```
    3.2 Process message
    ```objective-c
    - (void) queueMessageManager:(nonnull PDAQueueMessageManager *)manager
               handleMessage:(nonnull id<PDAQueueCommand>)message
                  completion:(nonnull PDAResponseBlock)responseBlock
   {
        /// Process message
        responseBlock(nil,nil);
    }
    ```
    3.3 Handle a parse error. You could simply return null if you don't want process error
    ```objective-c
    - (nullable id<PDAQueueCommand>) queueMessageManager:(nonnull PDAQueueMessageManager *)manager
                                   resolveParseError:(nonnull NSError *)parseError
    {
        return nil;
    }
    ```
4. If you intresting in changing class which represents message(by default it's PDAQueueCommand) you could do it by
    ```objective-c
    manager.queueMessageClass = [YourClass class];
    ```
    It could be usefull for Fabric Method  https://rudenerd.me/2013/01/23/ios-patterns-fabric-method/
    