//
//  ChatManager.m
//  QBRTCChatSemple
//
//  Created by Andrey Ivanov on 12.12.14.
//  Copyright (c) 2014 QuickBlox Team. All rights reserved.
//

#import "ChatManager.h"
#import "UsersDataSource.h"

const NSTimeInterval kChatPresenceTimeInterval = 45;

@interface ChatManager ()

<QBChatDelegate>

@property (copy, nonatomic) void(^chatLoginCompletionBlock)(BOOL error);
@property (copy, nonatomic) dispatch_block_t chatDisconnectedBlock;
@property (copy, nonatomic) dispatch_block_t chatReconnectedBlock;
@property (strong, nonatomic) QBRTCTimer *presenceTimer;

@end

@implementation ChatManager

+ (instancetype)instance {
    
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

#pragma mark - Login / Logout

- (void)logInWithUser:(QBUUser *)user completion:(void (^)(BOOL error))completion  disconnectedBlock:(dispatch_block_t)disconnectedBlock reconnectedBlock:(dispatch_block_t)reconnectedBlock{

    [QBChat.instance addDelegate:self];
    
    if (QBChat.instance.isConnected) {
        completion(NO);
        return;
    }
    
    self.chatLoginCompletionBlock = completion;
	self.chatDisconnectedBlock = disconnectedBlock;
	self.chatReconnectedBlock = reconnectedBlock;
    [QBChat.instance connectWithUser:user completion:^(NSError * _Nullable error) {
        
    }];
}

- (void)logOut {
    
    [self.presenceTimer invalidate];
    self.presenceTimer = nil;
    
    if ([QBChat.instance isConnected]) {
        [QBChat.instance disconnectWithCompletionBlock:^(NSError * _Nullable error) {
            
        }];
    }
}

#pragma mark - QBChatDelegate

- (void)chatDidNotLogin {
    
    if (self.chatLoginCompletionBlock) {
        
        self.chatLoginCompletionBlock(YES);
        self.chatLoginCompletionBlock = nil;
    }
}

- (void)chatDidAccidentallyDisconnect {
    
	if (self.chatLoginCompletionBlock) {
        
		self.chatLoginCompletionBlock(YES);
		self.chatLoginCompletionBlock = nil;
	}
	if (self.chatDisconnectedBlock) {
		self.chatDisconnectedBlock();
	}
}

- (void)chatDidNotConnectWithError:(NSError *)error {
    
	if (self.chatLoginCompletionBlock) {
        
		self.chatLoginCompletionBlock(YES);
		self.chatLoginCompletionBlock = nil;
	}
}

- (void)chatDidFailWithStreamError:(NSError *)error {
    
    if (self.chatLoginCompletionBlock) {
        
        self.chatLoginCompletionBlock(YES);
        self.chatLoginCompletionBlock = nil;
    }
}

- (void)chatDidLogin {
    
    [[QBChat instance] sendPresence];
    __weak __typeof(self)weakSelf = self;
    
    self.presenceTimer = [[QBRTCTimer alloc] initWithTimeInterval:kChatPresenceTimeInterval
                                                           repeat:YES
                                                            queue:dispatch_get_main_queue()
                                                       completion:^{
         [[QBChat instance] sendPresence];
                                                           
    } expiration:^{
        
        if ([QBChat.instance isConnected]) {
            [QBChat.instance disconnect];
        }
        
        [weakSelf.presenceTimer invalidate];
        weakSelf.presenceTimer = nil;
    }];
    
    self.presenceTimer.label = @"Chat presence timer";
    
    if (self.chatLoginCompletionBlock) {
        
        self.chatLoginCompletionBlock(NO);
        self.chatLoginCompletionBlock = nil;
    }
}

- (void)chatDidReconnect {
	if (self.chatReconnectedBlock) {
		self.chatReconnectedBlock();
	}
}

@end
