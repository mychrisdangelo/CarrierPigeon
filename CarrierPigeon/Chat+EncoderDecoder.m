//
//  Chat+EncoderDecoder.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/4/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat+EncoderDecoder.h"
#import "Chat+Create.h"
#import "Chat+IdentificationNumberMaker.h"

@implementation Chat (EncoderDecoder)

+ (NSDictionary *)encodeChatAsDictionary:(Chat *)chat
{
    NSArray *attributes = [[[chat entity] attributesByName] allKeys];
    NSMutableDictionary *chatDictionary = [[NSMutableDictionary alloc] init];
    
    for (NSString *eachAttribute in attributes) {
        id value = [chat valueForKey:eachAttribute];
        
        if (value != nil) {
            chatDictionary[eachAttribute] = value;
        }
    }
    
    return [chatDictionary copy];
}

+ (Chat *)decodeDictionaryToChat:(NSDictionary *)chatDictionary inManagedObjectContext:(NSManagedObjectContext *)context asMessageRelayedByCurrentUser:(NSString *)currentUser
{
    Chat *decodedChat = [NSEntityDescription insertNewObjectForEntityForName:@"Chat" inManagedObjectContext:context];
    
    NSArray *attributes = [chatDictionary allKeys];
    
    for (NSString *eachAttribute in attributes) {
        id value = chatDictionary[eachAttribute];
        
        if (value != nil) {
            [decodedChat setValue:value forKey:eachAttribute];
        }
    }
    
    if (currentUser) {
        decodedChat.reallyFromJID = decodedChat.fromJID;
        decodedChat.fromJID = currentUser;
        decodedChat.messageStatus = [NSNumber numberWithInt:CPChatSendStatusOfflinePending];
        /*
         * chatOwner represents the user that is logged in. they can hold onto messages they are sending, they have received
         * or any message that they are relaying is always "owned" by the chatOwner
         */
        decodedChat.chatOwner = currentUser;
        
        /*
         * When a message is received peer to peer it comes with a chatIDNumberPerOwner that represents the original sender's
         * sent message id. It arrives on the carrier's device and this number is NOT the chatIDNumberPerOwner.
         * We must reassign and also create our own chatIDNumber for the owner
         */
        decodedChat.reallyFromChatIDNumber = decodedChat.chatIDNumberPerOwner;
        NSUInteger chatIDNumber = [Chat generateNewIDNumberWithManagedObjectContext:context withCurrentUser:currentUser];
        decodedChat.chatIDNumberPerOwner = [NSNumber numberWithInteger:chatIDNumber];
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"error saving");
    }
    
    return decodedChat;
}


@end
