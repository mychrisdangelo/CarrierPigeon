//
//  Chat+Create.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat.h"
#import "XMPPMessage.h"
#import "XMPPUserCoreDataStorageObject.h"

typedef NS_ENUM(NSInteger, CPMessageStatus) {
    CPChatSendStutusReceivedMessage,
    CPChatSendStatusSending,
    CPChatSendStatusSent,
    CPChatStatusOfflinePending,
    CPChatStatusRelaying
};

@interface Chat (Create)

+ (Chat *)addChatWithXMPPMessage:(XMPPMessage *)message
                        fromUser:(NSString *)fromUser
                          toUser:(NSString *)toUser
                      deviceUser:(NSString *)deviceUser
          inManagedObjectContext:(NSManagedObjectContext *)context
                  withMessageStatus:(CPMessageStatus)sendStatus;

@end
