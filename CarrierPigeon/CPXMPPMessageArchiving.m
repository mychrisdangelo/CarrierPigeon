//
//  CPXMPPMessageArchiving.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/29/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPXMPPMessageArchiving.h"

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

@end
