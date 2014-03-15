//
//  CPMessenger.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/14/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPMessenger.h"
#import "Chat+Create.h"

@implementation CPMessenger

+(void)sendMessage:(NSString *)messageBody
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
    
    CPMessageStatus sendStatus;
    if ([xmppStream isConnected]) {
        sendStatus = CPChatSendStatusSending;
        [xmppStream sendElement:messageElement];
    } else {
        sendStatus = CPChatStatusOfflinePending;
    }
        
    XMPPMessage *message = [XMPPMessage messageFromElement:messageElement];
    [Chat addChatWithXMPPMessage:message fromUser:from toUser:to deviceUser:deviceUser inManagedObjectContext:context withMessageStatus:sendStatus];
}
    
@end
