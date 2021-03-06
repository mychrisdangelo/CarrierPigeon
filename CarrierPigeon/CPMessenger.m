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
#import "XMPPMessageDeliveryReceipts.h"
#import "Chat+IdentificationNumberMaker.h"

@implementation CPMessenger

+ (void)sendMessage:(NSString *)messageBody
              from:(NSString *)from
                to:(NSString *)to
        deviceUser:(NSString *)deviceUser
      onXMPPStream:(XMPPStream *)xmppStream
inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSUInteger chatIDNumber = [Chat generateNewIDNumberWithManagedObjectContext:context withCurrentUser:deviceUser];
    
    NSDate *sendDate = [NSDate date];
    int sendDateTimestamp = [sendDate timeIntervalSince1970];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageBody];
    NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
    [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
    [messageElement addAttributeWithName:@"to" stringValue:to];
    [messageElement addAttributeWithName:@"senderTimestamp" stringValue:[NSString stringWithFormat:@"%d", sendDateTimestamp]];
    [messageElement addAttributeWithName:@"serverTimestamp" stringValue:@""];
    [messageElement addChild:body];
    [messageElement addAttributeWithName:@"id" stringValue:[NSString stringWithFormat:@"%lu", (unsigned long)chatIDNumber]];
    NSXMLElement *status = [NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"];
    [messageElement addChild:status];
    
    CPMessageStatus sendStatus = CPChatSendStatusOfflinePending;
    XMPPMessage *message = [XMPPMessage messageFromElement:messageElement];
    CPSessionContainer *sc = [CPSessionContainer sharedInstance];
    
    // if we can send via the server do that
    if ([xmppStream isConnected]) {
        // TODO: this is premature. We should wait for message receipt
        sendStatus = CPChatSendStatusSent;
        
        // TODO: Waiting on server side implementation of message receipts
        XMPPElementReceipt *receipt = [[XMPPElementReceipt alloc] init];
        [xmppStream sendElement:messageElement andGetReceipt:&receipt];
        
        [Chat addChatWithXMPPMessage:message fromUser:from toUser:to deviceUser:deviceUser inManagedObjectContext:context withMessageStatus:sendStatus withChatIDNumber:chatIDNumber];
        
    } else if ([sc.peersInRange count] > 0) {
        sendStatus = CPChatSendStatusRelaying;
        [sc sendChat:[Chat addChatWithXMPPMessage:message fromUser:from toUser:to deviceUser:deviceUser inManagedObjectContext:context withMessageStatus:sendStatus withChatIDNumber:chatIDNumber]];
    } else {
        [Chat addChatWithXMPPMessage:message fromUser:from toUser:to deviceUser:deviceUser inManagedObjectContext:context withMessageStatus:sendStatus withChatIDNumber:chatIDNumber];
    }
}

+ (NSString *)myJid
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
}

+ (void)sendPendingMessagesWithStream:(XMPPStream *)xmppStream
{
    NSManagedObjectContext *context = ((CPAppDelegate *)([[UIApplication sharedApplication] delegate])).managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chat" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageStatus = %@ OR messageStatus = %@ OR messageStatus = %@",
                              [NSNumber numberWithInt:CPChatSendStatusOfflinePending],
                              [NSNumber numberWithInt:CPChatSendStatusRelaying],
                              [NSNumber numberWithInt:CPChatSendStatusRelayed]];
    // only allow currently signed in user to send out their own messages
    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [NSPredicate predicateWithFormat:@"chatOwner == %@", [CPMessenger myJid]]]];
    NSSortDescriptor *s = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setSortDescriptors:@[s]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
    NSDate *sendDate = nil;
    int sendDateTimestamp = 0;
    
    for (Chat *each in matches) {
        sendDate = [NSDate date];
        sendDateTimestamp = [sendDate timeIntervalSince1970];
        
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:each.messageBody];
        NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
        [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
        [messageElement addAttributeWithName:@"to" stringValue:each.toJID];
        [messageElement addAttributeWithName:@"senderTimestamp" stringValue:[NSString stringWithFormat:@"%d", sendDateTimestamp]];
        [messageElement addAttributeWithName:@"serverTimestamp" stringValue:@""];
        [messageElement addChild:body];
        [messageElement addAttributeWithName:@"id" integerValue:[each.chatIDNumberPerOwner integerValue]];
        NSXMLElement *status = [NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"];
        [messageElement addChild:status];
        
        if (each.reallyFromJID) {
            [messageElement addAttributeWithName:@"reallyFrom" stringValue:each.reallyFromJID];
            [messageElement addAttributeWithName:@"reallyFromID" integerValue:[each.reallyFromChatIDNumber integerValue]];
        }
        
        CPMessageStatus sendStatus = CPChatSendStatusOfflinePending;
        CPSessionContainer *sc = [CPSessionContainer sharedInstance];
        if ([xmppStream isConnected]) {
            // TODO: this is premature. We should wait for message receipt
            sendStatus = CPChatSendStatusSent;
            
            // TODO: Waiting on server side implementation of message receipts
            XMPPElementReceipt *receipt = [[XMPPElementReceipt alloc] init];
            [xmppStream sendElement:messageElement andGetReceipt:&receipt];
            
            [Chat updateChat:each withStatus:sendStatus inManagedObjectContext:context];
        } else if ([sc.peersInRange count] > 0) {
            /*
             * Messages received from others to relay are not sent to subsquent peers. Here, the current
             * user is a carrier of the message. They should not send out a relayed messages to other peers. They
             * should only send directly to the server if they can.
             */
            
            if (!each.reallyFromJID) {
                sendStatus = CPChatSendStatusRelaying;
                [sc sendChat:[Chat updateChat:each withStatus:sendStatus inManagedObjectContext:context]];
            }
        } else {
            [Chat updateChat:each withStatus:sendStatus inManagedObjectContext:context];
        }
    }
}

@end
