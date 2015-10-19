//
//  FriendsListViewController.m
//  IMChatDemo
//
//  Created by lujiangbin on 15/10/14.
//  Copyright © 2015年 lujiangbin. All rights reserved.
//


#import "FriendsListViewController.h"
#import "JBXMPPManager.h"
#import "ChatViewController.h"

@interface FriendsListViewController ()

@property (nonatomic, strong) NSMutableArray    *friendsList;

@end

@implementation FriendsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.friendsList = [[NSMutableArray alloc] init];
    
    //获取服务器好友列表
    [[[JBXMPPManager sharedInstance] xmppRoster] fetchRoster];
    
    //监听好友变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rosterChange) name:@"RosterChanged" object:nil];
}

#pragma mark -- 更新好友

- (void)rosterChange
{
    self.friendsList = [NSMutableArray arrayWithArray:[JBXMPPManager sharedInstance].xmppRosterMemoryStorage.unsortedUsers];
    [self.tableView reloadData];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.friendsList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendsListCell" forIndexPath:indexPath];
    
    XMPPUserMemoryStorageObject *user = self.friendsList[indexPath.row];
    
    cell.imageView.image = [UIImage imageNamed:@"UserImage"];
    cell.textLabel.text = user.jid.user;
    
    if ([user isOnline])
    {
        cell.detailTextLabel.text = @"[在线]";
    } else
    {
        cell.detailTextLabel.text = @"[离线]";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPUserMemoryStorageObject *user = self.friendsList[indexPath.row];
    ChatViewController *chatVC = [[ChatViewController alloc] init];
    chatVC.chatJID = user.jid;
    [self.navigationController pushViewController:chatVC animated:YES];
}


@end
