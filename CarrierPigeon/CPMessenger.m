//
//  CPMessenger.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/14/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPMessenger.h"
#import "Chat+Create.h"
#import "CPAppDelegate.h"
#import "CPSessionContainer.h"

@implementation CPMessenger

+ (void)sendMessage:(NSString *)messageBody
              from:(NSString *)from
                to:(NSString *)to
        deviceUser:(NSString *)deviceUser
      onXMPPStream:(XMPPStream *)xmppStream
inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageBody];
    NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
    [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
    [messageElement addAttributeWithName:@"to" stringValue:to];
    [messageElement addChild:body];
    NSXMLElement *status = [NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"];
    [messageElement addChild:status];
    
    CPMessageStatus sendStatus = CPChatStatusOfflinePending;
    XMPPMessage *message = [XMPPMessage messageFromElement:messageElement];
    CPSessionContainer *sc = [CPSessionContainer sharedInstance];
    // if we can send via the server do that
    if ([xmppStream isConnected]) {
        sendStatus = CPChatSendStatusSending;
        [xmppStream sendElement:messageElement];
    } else if ([sc.peersInRange count] > 0) {
        sendStatus = CPChatStatusRelayed;
        [sc sendChat:[Chat addChatWithXMPPMessage:message fromUser:from toUser:to deviceUser:deviceUser inManagedObjectContext:context withMessageStatus:sendStatus]];
    } else {
        [Chat addChatWithXMPPMessage:message fromUser:from toUser:to deviceUser:deviceUser inManagedObjectContext:context withMessageStatus:sendStatus];
    }
}

+ (void)sendPendingMessagesWithStream:(XMPPStream *)xmppStream
{
    NSManagedObjectContext *context = ((CPAppDelegate *)([[UIApplication sharedApplication] delegate])).managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chat" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageStatus = %@ OR messageStatus = %@ OR messageStatus = %@",
                              [NSNumber numberWithInt:CPChatStatusOfflinePending], [NSNumber numberWithInt:CPChatStatusRelaying],
                              [NSNumber numberWithInt:CPChatStatusRelayed]];
    NSSortDescriptor *s = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setSortDescriptors:@[s]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
    
    for (Chat *each in matches) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:each.messageBody];
        NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
        [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
        [messageElement addAttributeWithName:@"to" stringValue:each.toJID];
        [messageElement addChild:body];
        NSXMLElement *status = [NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"];
        [messageElement addChild:status];
        
        CPMessageStatus sendStatus = CPChatStatusOfflinePending;
        if ([xmppStream isConnected]) {
            sendStatus = CPChatSendStatusSending;
            [xmppStream sendElement:messageElement];
        }
        
        [Chat updateChat:each withStatus:sendStatus inManagedObjectContext:context];
    }
}

@end
