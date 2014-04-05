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
    CPChatSendStatusReceivedMessage,
    CPChatSendStatusSending,
    CPChatSendStatusSent,
    CPChatSendStatusArrived,
    CPChatSendStatusRead,
    CPChatSendStatusOfflinePending,
    CPChatSendStatusRelaying,
    CPChatSendStatusRelayed
};

@interface Chat (Create)

+ (Chat *)addChatWithXMPPMessage:(XMPPMessage *)message
                        fromUser:(NSString *)fromUser
                          toUser:(NSString *)toUser
                      deviceUser:(NSString *)deviceUser
          inManagedObjectContext:(NSManagedObjectContext *)context
               withMessageStatus:(CPMessageStatus)messageStatus
                withChatIDNumber:(NSUInteger)chatIDNumber;

+ (Chat *)updateChat:(Chat *)chat withStatus:(CPMessageStatus)messageStatus inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Chat *)updateChat:(Chat *)chat withPigeonsCarryingMessage:(NSArray *)carrierPigeons inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSString *)stringForMessageStatus:(CPMessageStatus)messageStatus;

@end
