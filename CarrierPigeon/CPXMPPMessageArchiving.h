//
//  CPXMPPMessageArchiving.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/29/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "XMPPModule.h"
#import "XMPPIQ.h"
#import "XMPPStream.h"

@interface CPXMPPMessageArchiving : NSObject

+ (void)getChatsOnStream:(XMPPStream *)xmppStream withFromJidStr:(NSString *)fromJidStr withMaxConversations:(int)maxConversations;
+ (void)saveChatsFromArchiveResultsIq:(XMPPIQ *)resultIq onStream:(XMPPStream *)stream;

@end
