//
//  JBXMPPManager.h
//  IMChatDemo
//
//  Created by lujiangbin on 15/10/13.
//  Copyright © 2015年 lujiangbin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPStreamManagement.h"
#import "XMPPStreamManagementMemoryStorage.h"
#import "XMPPRosterMemoryStorage.h"
#import "XMPPMessageArchiving.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPIncomingFileTransfer.h"
#import "XMPPOutgoingFileTransfer.h"


#define JBXMPP_HOST @"lujiangbin.local"
#define JBXMPP_PORT 5222

#define JBXMPP_DOMAIN @"lujiangbin.local"

@interface JBXMPPManager : NSObject

@property (nonatomic, strong) XMPPStream *xmppStream;

// 模块
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, copy)   NSString *myPassword;
@property (nonatomic, strong)   XMPPJID *myJID;

@property(nonatomic,strong)XMPPStreamManagementMemoryStorage *storage;
@property(nonatomic,strong)XMPPStreamManagement *xmppStreamManagement;

@property (nonatomic, strong) XMPPIncomingFileTransfer *xmppIncomingFileTransfer;

@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRosterMemoryStorage *xmppRosterMemoryStorage;

@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchiving;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage;

+ (instancetype)sharedInstance;

/**
 *  登陆
 *
 *  @param JID      用户名: user1
 *  @param password 密码
 */
- (void)loginWithName:(NSString *)userName andPassword:(NSString *)password;

/**
 *  退出登录
 */
- (void)logOut;

/**
 *  上线
 */
- (void)goOnline;

/**
 *  下线
 */
- (void)goOffline;

/**
 *  发送消息
 *
 *  @param message 消息内容
 *  @param jid     发送对方的ID
 */
- (void)sendMessage:(NSString *)message to:(XMPPJID *)jid;

@end
