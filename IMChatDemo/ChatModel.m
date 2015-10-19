//
//  ChatModel.m
//  UUChatTableView
//
//  Created by shake on 15/1/6.
//  Copyright (c) 2015年 uyiuyao. All rights reserved.
//

#import "JBXMPPManager.h"
#import "ChatModel.h"
#import "UUMessage.h"
#import "UUMessageFrame.h"
#import "VoiceConverter.h"

@implementation ChatModel

- (void)populateRandomDataSource {
    self.dataSource = [NSMutableArray array];
    [self.dataSource addObjectsFromArray:[self additems:5]];
}

-(void)getMessageHistoryWithJID:(XMPPJID*)jid
{
    self.dataSource = [NSMutableArray array];
    XMPPMessageArchivingCoreDataStorage *storage = [JBXMPPManager sharedInstance].xmppMessageArchivingCoreDataStorage;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:storage.messageEntityName inManagedObjectContext:storage.mainThreadManagedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr = %@", jid.bare];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [storage.mainThreadManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects != nil) {
        
        for (int i=0; i<fetchedObjects.count; i++)
        {
            XMPPMessageArchiving_Message_CoreDataObject *recordMessage = fetchedObjects[i];
            NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
            
            UUMessage *message = [[UUMessage alloc] init];
            
            NSString *myStr = @"http://img0.bdstatic.com/img/image/shouye/xinshouye/mingxing16.jpg";
            NSString *otherStr =@"http://p1.qqyou.com/touxiang/uploadpic/2011-3/20113212244659712.jpg";
            
            //对方发的消息，显示在左边
            BOOL fromOthers = recordMessage.message.from;
            
            [dataDic setObject:fromOthers ? @(UUMessageFromOther):@(UUMessageFromMe) forKey:@"from"];
            [dataDic setObject:[recordMessage.timestamp description] forKey:@"strTime"];
            [dataDic setObject:fromOthers?recordMessage.bareJidStr:[JBXMPPManager sharedInstance].myJID.user forKey:@"strName"];
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
            
            [message setWithDict:dataDic];
            [message minuteOffSetStart:previousTime end:dataDic[@"strTime"]];
            
            UUMessageFrame *messageFrame = [[UUMessageFrame alloc]init];
            messageFrame.showTime = message.showDateLabel;
            [messageFrame setMessage:message];
            
            if (message.showDateLabel) {
                previousTime = dataDic[@"strTime"];
            }
            [self.dataSource addObject:messageFrame];
        }

    }
}

- (void)addRandomItemsToDataSource:(NSInteger)number{
    
    for (int i=0; i<number; i++) {
        [self.dataSource insertObject:[[self additems:1] firstObject] atIndex:0];
    }
}

// 添加自己的item
- (void)addSpecifiedItem:(NSDictionary *)dic
{
    UUMessageFrame *messageFrame = [[UUMessageFrame alloc]init];
    UUMessage *message = [[UUMessage alloc] init];
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    
    [message setWithDict:dataDic];
    [message minuteOffSetStart:previousTime end:dataDic[@"strTime"]];
    messageFrame.showTime = message.showDateLabel;
    [messageFrame setMessage:message];
    
    if (message.showDateLabel) {
        previousTime = dataDic[@"strTime"];
    }
    [self.dataSource addObject:messageFrame];
}

// 添加聊天item（一个cell内容）
static NSString *previousTime = nil;
- (NSArray *)additems:(NSInteger)number
{
    NSMutableArray *result = [NSMutableArray array];
    
    for (int i=0; i<number; i++) {
        
        NSDictionary *dataDic = [self getDic];
        UUMessageFrame *messageFrame = [[UUMessageFrame alloc]init];
        UUMessage *message = [[UUMessage alloc] init];
        [message setWithDict:dataDic];
        [message minuteOffSetStart:previousTime end:dataDic[@"strTime"]];
        messageFrame.showTime = message.showDateLabel;
        [messageFrame setMessage:message];
        
        if (message.showDateLabel) {
            previousTime = dataDic[@"strTime"];
        }
        [result addObject:messageFrame];
    }
    return result;
}

// 如下:群聊（groupChat）
static int dateNum = 10;
- (NSDictionary *)getDic
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    int randomNum = arc4random()%5;
    if (randomNum == UUMessageTypePicture) {
        [dictionary setObject:[UIImage imageNamed:[NSString stringWithFormat:@"%zd.jpeg",arc4random()%2]] forKey:@"picture"];
    }else{
        // 文字出现概率4倍于图片（暂不出现Voice类型）
        randomNum = UUMessageTypeText;
        [dictionary setObject:[self getRandomString] forKey:@"strContent"];
    }
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:arc4random()%1000*(dateNum++) ];
    [dictionary setObject:@(UUMessageFromOther) forKey:@"from"];
    [dictionary setObject:@(randomNum) forKey:@"type"];
    [dictionary setObject:[date description] forKey:@"strTime"];
    int index =  0;
    [dictionary setObject:[self getName:index] forKey:@"strName"];
    [dictionary setObject:[self getImageStr:index] forKey:@"strIcon"];
    
    return dictionary;
}

- (NSString *)getRandomString {
    
    NSString *lorumIpsum = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent non quam ac massa viverra semper. Maecenas mattis justo ac augue volutpat congue. Maecenas laoreet, nulla eu faucibus gravida, felis orci dictum risus, sed sodales sem eros eget risus. Morbi imperdiet sed diam et sodales.";
    
    NSArray *lorumIpsumArray = [lorumIpsum componentsSeparatedByString:@" "];
    
    int r = arc4random() % [lorumIpsumArray count];
    r = MAX(6, r); // no less than 6 words
    NSArray *lorumIpsumRandom = [lorumIpsumArray objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, r)]];
    
    return [NSString stringWithFormat:@"%@!!", [lorumIpsumRandom componentsJoinedByString:@" "]];
}

- (NSString *)getImageStr:(NSInteger)index{
    NSArray *array = @[@"http://www.120ask.com/static/upload/clinic/article/org/201311/201311061651418413.jpg",
                       @"http://p1.qqyou.com/touxiang/uploadpic/2011-3/20113212244659712.jpg",
                       @"http://www.qqzhi.com/uploadpic/2014-09-14/004638238.jpg",
                       @"http://e.hiphotos.baidu.com/image/pic/item/5ab5c9ea15ce36d3b104443639f33a87e950b1b0.jpg",
                       @"http://ts1.mm.bing.net/th?&id=JN.C21iqVw9uSuD2ZyxElpacA&w=300&h=300&c=0&pid=1.9&rs=0&p=0",
                       @"http://ts1.mm.bing.net/th?&id=JN.7g7SEYKd2MTNono6zVirpA&w=300&h=300&c=0&pid=1.9&rs=0&p=0"];
    return array[index];
}

- (NSString *)getName:(NSInteger)index{
    NSArray *array = @[@"Hi,Daniel",@"Hi,Juey",@"Hey,Jobs",@"Hey,Bob",@"Hah,Dane",@"Wow,Boss"];
    return array[index];
}
@end
