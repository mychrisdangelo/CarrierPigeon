//
//  Chat+Create.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat+Create.h"


@implementation Chat (Create)

+ (Chat *)addChatWithXMPPMessage:(XMPPMessage *)message
                        fromUser:(NSString *)fromUser
                          toUser:(NSString *)toUser
                      deviceUser:(NSString *)deviceUser
          inManagedObjectContext:(NSManagedObjectContext *)context
                  withMessageStatus:(CPMessageStatus)messageStatus
{
    Chat *chat = [NSEntityDescription insertNewObjectForEntityForName:@"Chat" inManagedObjectContext:context];
    
    chat.messageBody = [[message elementForName:@"body"] stringValue];
    chat.timeStamp = [NSDate date];
    chat.messageStatus = [NSNumber numberWithInteger:messageStatus];
    chat.isIncomingMessage = [NSNumber numberWithBool:![deviceUser isEqualToString:fromUser]];
    chat.isNew = [NSNumber numberWithBool:YES];
    chat.hasMedia = [NSNumber numberWithBool:NO];
    chat.fromJID = fromUser;
    chat.toJID = toUser;
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"error saving");
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessageReceivedNotificationIdentifier object:self userInfo:nil];
    
    return chat;
}

@end