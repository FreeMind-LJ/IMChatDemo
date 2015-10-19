//
//  RootViewController.m
//  UUChatTableView
//
//  Created by shake on 15/1/4.
//  Copyright (c) 2015年 uyiuyao. All rights reserved.
//

#import "ChatViewController.h"
#import "UUInputFunctionView.h"
#import "MJRefresh.h"
#import "UUMessageCell.h"
#import "ChatModel.h"
#import "UUMessageFrame.h"
#import "UUMessage.h"

#import "VoiceConverter.h"


@interface ChatViewController ()<UUInputFunctionViewDelegate,UUMessageCellDelegate,UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) MJRefreshHeaderView *head;
@property (strong, nonatomic) ChatModel *chatModel;

@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@end

@implementation ChatViewController{
    UUInputFunctionView *IFView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addRefreshViews];
    [self loadBaseViewsAndData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //add notification
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tableViewScrollToBottom) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewsMessage:) name:@"DidReceiveNewMessage" object:nil];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)addRefreshViews
{
    __weak typeof(self) weakSelf = self;
    
    //load more
    int pageNum = 3;
    
    _head = [MJRefreshHeaderView header];
    _head.scrollView = self.chatTableView;
    _head.beginRefreshingBlock = ^(MJRefreshBaseView *refreshView) {
        
        [weakSelf.chatModel addRandomItemsToDataSource:pageNum];
        
        if (weakSelf.chatModel.dataSource.count > pageNum) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:pageNum inSection:0];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.chatTableView reloadData];
                [weakSelf.chatTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            });
        }
        [weakSelf.head endRefreshing];
    };
}

- (void)loadBaseViewsAndData
{
    self.chatModel = [[ChatModel alloc]init];
    
    //从本地数据库获取历史消息
    [self.chatModel getMessageHistoryWithJID:_chatJID];
    
    IFView = [[UUInputFunctionView alloc]initWithSuperVC:self];
    IFView.delegate = self;
    [self.view addSubview:IFView];
    
    [self.chatTableView reloadData];
    [self tableViewScrollToBottom];
}

-(void)keyboardChange:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    //adjust ChatTableView's height
    if (notification.name == UIKeyboardWillShowNotification) {
        self.bottomConstraint.constant = keyboardEndFrame.size.height+40;
    }else{
        self.bottomConstraint.constant = 40;
    }
    
    [self.view layoutIfNeeded];
    
    //adjust UUInputFunctionView's originPoint
    CGRect newFrame = IFView.frame;
    newFrame.origin.y = keyboardEndFrame.origin.y - newFrame.size.height;
    IFView.frame = newFrame;
    
    [UIView commitAnimations];
    
}

//tableView Scroll to bottom
- (void)tableViewScrollToBottom
{
    if (self.chatModel.dataSource.count==0)
        return;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chatModel.dataSource.count-1 inSection:0];
    [self.chatTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

-(void)handleNewsMessage:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    XMPPMessageArchiving_Message_CoreDataObject *recordMessage = userInfo[@"message"];
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    
    NSString *myStr = @"http://img0.bdstatic.com/img/image/shouye/xinshouye/mingxing16.jpg";
    NSString *otherStr =@"http://p1.qqyou.com/touxiang/uploadpic/2011-3/20113212244659712.jpg";
    
    //对方发的消息，显示在左边
    BOOL fromOthers = recordMessage.message.from;
    
    [dataDic setObject:fromOthers ? @(UUMessageFromOther):@(UUMessageFromMe) forKey:@"from"];
    [dataDic setObject:[recordMessage.timestamp description] forKey:@"strTime"];
    [dataDic setObject:fromOthers?recordMessage.bareJid.user:[JBXMPPManager sharedInstance].myJID.user forKey:@"strName"];
    [dataDic setObject:fromOthers ? otherStr:myStr forKey:@"strIcon"];
    
    
    //type:voice text picture
    NSNumber  *type;
    if ([recordMessage.message.subject isEqualToString:@"voice"]) {
        
        type = @(2);
        [dataDic setObject:[NSData dataWithContentsOfFile:recordMessage.body] forKey:@"voice"];
        [dataDic setObject:@([recordMessage.message attributeIntValueForName:@"VoiceLength"]) forKey:@"strVoiceTime"];
    }else if ([recordMessage.message.subject isEqualToString:@"picture"]){
        type = @(1);
        [dataDic setObject:[UIImage imageNamed:recordMessage.body] forKey:@"picture"];
        
    }else{
        type = @(0);
        [dataDic setObject:recordMessage.body forKey:@"strContent"];
    }

    
    [dataDic setObject:type forKey:@"type"];
    
    [self dealTheFunctionData:dataDic];
    
}


#pragma mark - InputFunctionViewDelegate
- (void)UUInputFunctionView:(UUInputFunctionView *)funcView sendMessage:(NSString *)message
{
    [[JBXMPPManager sharedInstance] sendMessage:message to:_chatJID];
    funcView.TextViewInput.text = @"";
}

//音频跟图片压缩后 base64编码
- (void)UUInputFunctionView:(UUInputFunctionView *)funcView sendPicture:(UIImage *)image
{
    NSString* encodeData = [UIImageJPEGRepresentation(image, 1.0) base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    XMPPMessage* message = [[XMPPMessage alloc] initWithType:@"chat" to:_chatJID];
    [message addBody:encodeData];
    [message addSubject:@"picture"];
    [[JBXMPPManager sharedInstance].xmppStream sendElement:message];
}

- (void)UUInputFunctionView:(UUInputFunctionView *)funcView sendVoice:(NSData *)voice time:(NSInteger)second
{
    NSString* encodeData = [voice base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    XMPPMessage* message = [[XMPPMessage alloc] initWithType:@"chat" to:_chatJID];
    [message addBody:encodeData];
    [message addSubject:@"voice"];
    [message addAttributeWithName:@"VoiceLength" unsignedIntegerValue:second];
    [[JBXMPPManager sharedInstance].xmppStream sendElement:message];

}

- (void)dealTheFunctionData:(NSDictionary *)dic
{
    [self.chatModel addSpecifiedItem:dic];
    [self.chatTableView reloadData];
    [self tableViewScrollToBottom];
}

#pragma mark - tableView delegate & datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.chatModel.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UUMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellID"];
    if (cell == nil) {
        cell = [[UUMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellID"];
        cell.delegate = self;
    }
    [cell setMessageFrame:self.chatModel.dataSource[indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self.chatModel.dataSource[indexPath.row] cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.view endEditing:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self.view endEditing:YES];
}

#pragma mark - cellDelegate
- (void)headImageDidClick:(UUMessageCell *)cell userId:(NSString *)userId{
    // headIamgeIcon is clicked
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:cell.messageFrame.message.strName message:@"headImage clicked" delegate:nil cancelButtonTitle:@"sure" otherButtonTitles:nil];
    [alert show];
}

@end
