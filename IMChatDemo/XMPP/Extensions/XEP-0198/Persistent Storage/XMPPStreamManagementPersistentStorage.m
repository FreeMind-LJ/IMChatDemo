//
//  XMPPStreamManagementPersistentStorage.m
//  friendlib
//
//  Created by lujiangbin on 15/9/29.
//  Copyright © 2015年 Mac. All rights reserved.
//

#import "XMPPStreamManagementPersistentStorage.h"
#import <libkern/OSAtomic.h>
#import "XMPPStreamManagementStanzas.h"


@interface XMPPStreamManagementPersistentStorage ()
{
    int32_t isConfigured;
}

@end

@implementation XMPPStreamManagementPersistentStorage


- (BOOL)configureWithParent:(XMPPStreamManagement *)parent queue:(dispatch_queue_t)queue
{
    return OSAtomicCompareAndSwap32(0, 1, &isConfigured);
}

- (void)setResumptionId:(NSString *)inResumptionId
                timeout:(uint32_t)inTimeout
         lastDisconnect:(NSDate *)inLastDisconnect
              forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:inResumptionId forKey:@"resumptionId"];
    [userDefaults setObject:@(inTimeout) forKey:@"timeout"];
    [userDefaults setObject:inLastDisconnect forKey:@"lastDisconnect"];
    [userDefaults setObject:@(0) forKey:@"lastHandledByClient"];
    [userDefaults setObject:@(0) forKey:@"lastHandledByServer"];
    [userDefaults setObject:nil forKey:@"pendingOutgoingStanzas"];
    [userDefaults synchronize];
}

- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByClient:(uint32_t)inLastHandledByClient
                forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:inLastDisconnect forKey:@"lastDisconnect"];
    [userDefaults setObject:@(inLastHandledByClient) forKey:@"lastHandledByClient"];
    [userDefaults synchronize];
}

- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByServer:(uint32_t)inLastHandledByServer
   pendingOutgoingStanzas:(NSArray *)inPendingOutgoingStanzas
                forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:inLastDisconnect forKey:@"lastDisconnect"];
    [userDefaults setObject:@(inLastHandledByServer) forKey:@"lastHandledByServer"];
    //[userDefaults setObject:inPendingOutgoingStanzas forKey:@"pendingOutgoingStanzas"];
    
    
    
    NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:inPendingOutgoingStanzas.count];
    for (XMPPStreamManagementOutgoingStanza *stanzas in inPendingOutgoingStanzas) {
        NSData *stanzasData = [NSKeyedArchiver archivedDataWithRootObject:stanzas];
        [archiveArray addObject:stanzasData];
    }
    [userDefaults setObject:archiveArray forKey:@"pendingOutgoingStanzas"];
    
    [userDefaults synchronize];
}

- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByClient:(uint32_t)inLastHandledByClient
      lastHandledByServer:(uint32_t)inLastHandledByServer
   pendingOutgoingStanzas:(NSArray *)inPendingOutgoingStanzas
                forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:inLastDisconnect forKey:@"lastDisconnect"];
    [userDefaults setObject:@(inLastHandledByClient) forKey:@"lastHandledByClient"];
    [userDefaults setObject:@(inLastHandledByServer) forKey:@"lastHandledByServer"];
    //[userDefaults setObject:inPendingOutgoingStanzas forKey:@"pendingOutgoingStanzas"];
    NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:inPendingOutgoingStanzas.count];
    for (XMPPStreamManagementOutgoingStanza *stanzas in inPendingOutgoingStanzas) {
        NSData *stanzasData = [NSKeyedArchiver archivedDataWithRootObject:stanzas];
        [archiveArray addObject:stanzasData];
    }
    [userDefaults setObject:archiveArray forKey:@"pendingOutgoingStanzas"];
    
    [userDefaults synchronize];
}

- (void)getResumptionId:(NSString **)resumptionIdPtr
                timeout:(uint32_t *)timeoutPtr
         lastDisconnect:(NSDate **)lastDisconnectPtr
              forStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (resumptionIdPtr)   *resumptionIdPtr   = [userDefaults valueForKey:@"resumptionId"];
    if (timeoutPtr)        *timeoutPtr        = [[userDefaults valueForKey:@"timeout"] unsignedIntValue];
    if (lastDisconnectPtr) *lastDisconnectPtr = [userDefaults valueForKey:@"lastDisconnect"];
}


- (void)getLastHandledByClient:(uint32_t *)lastHandledByClientPtr
           lastHandledByServer:(uint32_t *)lastHandledByServerPtr
        pendingOutgoingStanzas:(NSArray **)pendingOutgoingStanzasPtr
                     forStream:(XMPPStream *)stream;
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (lastHandledByClientPtr)    *lastHandledByClientPtr    = [[userDefaults valueForKey:@"lastHandledByClient"] unsignedIntValue];
    if (lastHandledByServerPtr)    *lastHandledByServerPtr    = [[userDefaults valueForKey:@"lastHandledByServer"] unsignedIntValue];
   // if (pendingOutgoingStanzasPtr) *pendingOutgoingStanzasPtr = [userDefaults valueForKey:@"pendingOutgoingStanzas"];
    
    if (pendingOutgoingStanzasPtr) {
        NSMutableArray *archiveArray = [userDefaults valueForKey:@"pendingOutgoingStanzas"];
        NSMutableArray *outgoingArray = [NSMutableArray arrayWithCapacity:archiveArray.count];
        for (NSData *data in archiveArray) {
            XMPPStreamManagementOutgoingStanza *outgoingStanza = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [outgoingArray addObject:outgoingStanza];
        }
        *pendingOutgoingStanzasPtr = outgoingArray;
    }

}

- (void)removeAllForStream:(XMPPStream *)stream
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:@"resumptionId"];
    [userDefaults setInteger:0 forKey:@"timeout"];
    [userDefaults setObject:nil forKey:@"lastDisconnect"];
    [userDefaults setInteger:0 forKey:@"lastHandledByClient"];
    [userDefaults setInteger:0 forKey:@"lastHandledByServer"];
    [userDefaults setObject:nil forKey:@"pendingOutgoingStanzas"];
    [userDefaults synchronize];
}


@end
