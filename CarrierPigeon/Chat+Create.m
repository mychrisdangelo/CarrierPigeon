//
//  Chat+Create.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat+Create.h"
#import "PigeonPeer+MCPeer.h"
#import "Chat+IdentificationNumberMaker.h"
#import "Contact+AddRemove.h"

@implementation Chat (Create)

+ (Contact *)getContactForThisMessageForUser:(NSString *)user andWithDeviceUser:(NSString *)deviceUser inManagedObjectContext:(NSManagedObjectContext *)context
{
    Contact *contact = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    request.predicate = [NSPredicate predicateWithFormat:@"jidStr = %@ AND contactOwnerJidStr = %@", user, deviceUser];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"jidStr" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        // sanity check
        NSLog(@"contact exists more than once");
    } else if ([matches count] == 0) {
        NSLog(@"contact doesn't exist for sent/received message. %s", __PRETTY_FUNCTION__);
    } else {
        // only one object found
        contact = [matches lastObject];
    }
    
    return contact;
}

+ (Chat *)addChatWithXMPPMessage:(XMPPMessage *)message
                        fromUser:(NSString *)fromUser
                          toUser:(NSString *)toUser
                      deviceUser:(NSString *)deviceUser
          inManagedObjectContext:(NSManagedObjectContext *)context
               withMessageStatus:(CPMessageStatus)messageStatus
                withChatIDNumber:(NSUInteger)chatIDNumber
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
    
    /* store the send date as UTC, retrieve in the user's timezone */
    NSString *statusString = [Chat stringForMessageStatus:[chat.messageStatus intValue]];
    int sendDateTimestamp = [[[message attributeForName:@"senderTimestamp"] stringValue] intValue];
    
    NSDate *sendDate = [NSDate dateWithTimeIntervalSince1970:sendDateTimestamp];
    chat.senderSentTimestamp = sendDate;

    if ([statusString isEqualToString:@"received"]) {
        chat.receiverReceivedTimestamp = [NSDate date];
    }
    
    if (![[[message attributeForName:@"serverTimestamp"] stringValue] isEqualToString:@""]) {
        int serverTimestamp = [[[message attributeForName:@"serverTimestamp"] stringValue] intValue];
        NSDate *serverDate = [NSDate dateWithTimeIntervalSince1970:serverTimestamp];
        chat.serverReceivedTimestamp = serverDate;
    }
    
    
    /*
     * chatOwner represents the user that is logged in. they can hold onto messages they are sending, they have received
     * or any message that they are relaying is always "owned" by the chatOwner
     */
    chat.chatOwner = deviceUser;
    if (chatIDNumber == -1) {
        // incoming message. use the fromUser's id number that they sent with message
        chat.chatIDNumberPerOwner = [NSNumber numberWithInteger:[[[message attributeForName:@"id"] stringValue] integerValue]];
    } else {
        chat.chatIDNumberPerOwner = [NSNumber numberWithInteger:chatIDNumber];
    }

    if ([chat.isIncomingMessage boolValue]) {
        Contact *author = [self getContactForThisMessageForUser:fromUser andWithDeviceUser:deviceUser inManagedObjectContext:context];
        [author addMessagesAuthoredObject:chat];
        chat.authorOfMessage = author;
        chat.recipientOfMessage = nil;
        
        chat.lastAuthorOrRecipient = author;
        author.lastMessageAuthoredOrReceived = chat;
    } else {
        // wire up relationship to chat's recipient
        Contact *recipient = [self getContactForThisMessageForUser:toUser andWithDeviceUser:deviceUser inManagedObjectContext:context];
        [recipient addMessagesReceivedObject:chat];
        chat.recipientOfMessage = recipient;
        chat.authorOfMessage = nil;
        
        chat.lastAuthorOrRecipient = recipient;
        recipient.lastMessageAuthoredOrReceived = chat;
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"error saving");
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessageReceivedNotificationIdentifier object:self userInfo:nil];
    
    return chat;
}

+ (Chat *)updateChat:(Chat *)chat withStatus:(CPMessageStatus)messageStatus inManagedObjectContext:(NSManagedObjectContext *)context
{
    chat.messageStatus = [NSNumber numberWithInteger:messageStatus];;
    NSError *error = nil;
    
    if (![context save:&error]) {
        NSLog(@"error saving");
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessageReceivedNotificationIdentifier object:self userInfo:nil];
    
    return chat;
}

+ (Chat *)updateChat:(Chat *)chat withPigeonsCarryingMessage:(NSArray *)carrierPigeons inManagedObjectContext:(NSManagedObjectContext *)context
{
    for (MCPeerID *eachPeer in carrierPigeons) {
        PigeonPeer *pigeon = [PigeonPeer addPigeonPeerWithMCPeerID:eachPeer inManagedObjectContext:context];
        [chat addPigeonsCarryingMessageObject:pigeon];
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"error saving");
    }
    
    return chat;
}

+ (NSString *)stringForMessageStatus:(CPMessageStatus)messageStatus
{
    NSString *statusString;
    
    switch (messageStatus) {
        case CPChatSendStatusSent:
            statusString = @"sent";
            break;
        case CPChatSendStatusSending:
            statusString = @"sending";
            break;
        case CPChatSendStatusReceivedMessage:
            statusString = @"received";
            break;
        case CPChatSendStatusOfflinePending:
            statusString = @"pending";
            break;
        case CPChatSendStatusRelaying:
            statusString = @"relaying";
            break;
        case CPChatSendStatusRelayed:
            statusString = @"relayed";
            break;
        case CPChatSendStatusArrived:
            statusString = @"arrived";
            break;
        case CPChatSendStatusRead:
            statusString = @"read";
            break;
        default:
            statusString = @"unknown";
            break;
    }
    
    return statusString;
}

+ (Chat *)updateChat:(Chat *)chat withTimestamp:(int)timestamp forServer:(BOOL)serverSending inManagedObjectContext:(NSManagedObjectContext *)context {
    
    // save the date as UTC (implemented on the server)
    NSDate *dateTimestamp = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)timestamp];
    NSError *error = nil;
    if (serverSending) {
        chat.serverReceivedTimestamp = dateTimestamp;
    } else {
        chat.receiverReceivedTimestamp = dateTimestamp;
    }
    
    if (![context save:&error]) {
        NSLog(@"error saving updated timestamp");
    }
    
    return chat;
}
@end