//
//  ChatModel.h
//  UUChatTableView
//
//  Created by shake on 15/1/6.
//  Copyright (c) 2015年 uyiuyao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JBXMPPManager.h"

@interface ChatModel : NSObject

@property (nonatomic, strong) NSMutableArray *dataSource;


- (void)populateRandomDataSource;

/**
 *  获取历史消息
 *
 *  @param jid 对方jid
 */
-(void) getMessageHistoryWithJID:(XMPPJID*)jid;

- (void)addRandomItemsToDataSource:(NSInteger)number;

- (void)addSpecifiedItem:(NSDictionary *)dic;

@end
