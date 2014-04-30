//
//  CPXMPPMessageArchiving.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/29/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPXMPPMessageArchiving.h"
#import "XMPP.h"

@implementation CPXMPPMessageArchiving

+ (void)getChatsOnStream:(XMPPStream *)xmppStream withFromJidStr:(NSString *)fromJidStr withMaxConversations:(int)maxConversations
{
    if (maxConversations <= 0) maxConversations = 30;
    
    DDXMLElement *iq = [DDXMLElement elementWithName:@"iq"];
    [iq addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"get"]];
    [iq addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:kXMPPArchiveListID]];
    
    DDXMLElement *list = [DDXMLElement elementWithName:@"list"];
    [list addAttribute:[DDXMLNode attributeWithName:@"xmlns" stringValue:@"http://www.xmpp.org/extensions/xep-0136.html#ns"]];
    [list addAttribute:[DDXMLNode attributeWithName:@"with" stringValue:fromJidStr]];
    
    DDXMLElement *set = [DDXMLElement elementWithName:@"set"];
    [set addAttribute:[DDXMLNode attributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/rsm"]];
    
    DDXMLElement *max = [DDXMLElement elementWithName:@"max"];
    [max setStringValue:[NSString stringWithFormat:@"%d", maxConversations]];
    
    [iq addChild:list];
    [list addChild:set];
    [set addChild:max];
    
    XMPPIQ *iqPackage = [XMPPIQ iqFromElement:iq];
    [xmppStream sendElement:iqPackage];
}

+ (void)sendRetrieveIqOnStream:(XMPPStream *)xmppStream fromWith:(NSString *)withString withStart:(NSString *)startString withMaxMessages:(int)maxMessages
{
    if (maxMessages <= -1) maxMessages = 100;
    
    DDXMLElement *iq = [DDXMLElement elementWithName:@"iq"];
    [iq addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:@"get"]];
    [iq addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:kXMPPArchiveRetrieveID]];
    
    DDXMLElement *retreive = [DDXMLElement elementWithName:@"retreive"];
    [retreive addAttribute:[DDXMLNode attributeWithName:@"xmlns" stringValue:@"http://www.xmpp.org/extensions/xep-0136.html#ns"]];
    [retreive addAttribute:[DDXMLNode attributeWithName:@"with" stringValue:withString]];
    [retreive addAttribute:[DDXMLNode attributeWithName:@"start" stringValue:startString]];
    
    DDXMLElement *set = [DDXMLElement elementWithName:@"set"];
    [set addAttribute:[DDXMLNode attributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/rsm"]];
    
    DDXMLElement *max = [DDXMLElement elementWithName:@"max"];
    [max setStringValue:[NSString stringWithFormat:@"%d", maxMessages]];
    
    [iq addChild:retreive];
    [retreive addChild:set];
    [set addChild:max];
    
    XMPPIQ *iqPackage = [XMPPIQ iqFromElement:iq];
    [xmppStream sendElement:iqPackage];
}

+ (void)saveChatsFromArchiveResultsIq:(XMPPIQ *)resultIq onStream:(XMPPStream *)xmppStream
{
    
    for (NSXMLElement *eachChatElement in [[resultIq elementForName:@"list"] elementsForName:@"chat"]) {
        NSString *with = [[eachChatElement attributeForName:@"with"] stringValue];
        NSString *start = [[eachChatElement attributeForName:@"start"] stringValue];
        
        [CPXMPPMessageArchiving sendRetrieveIqOnStream:xmppStream fromWith:with withStart:start withMaxMessages:100];
    }
}

@end
