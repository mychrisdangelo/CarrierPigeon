//
//  Chat+EncoderDecoder.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/4/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat+EncoderDecoder.h"
#import "Chat+Create.h"

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

+ (Chat *)decodeDictionaryToChat:(NSDictionary *)chatDictionary inManagedObjectContext:(NSManagedObjectContext *)context asMessageRelayedWithCurrentUser:(NSString *)currentUser
{
    Chat *decodedChat = [NSEntityDescription insertNewObjectForEntityForName:@"Chat" inManagedObjectContext:context];
    
    NSArray *attributes = [chatDictionary allKeys];
    
    for (NSString *eachAttribute in attributes) {
        id value = chatDictionary[eachAttribute];
        
        if (value != nil) {
            [decodedChat setValue:value forKey:eachAttribute];
        }
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"error saving");
    }
    
    if (currentUser) {
        decodedChat.reallyFromJID = decodedChat.fromJID;
        decodedChat.fromJID = currentUser;
        decodedChat.messageStatus = [NSNumber numberWithInt:CPChatSendStatusOfflinePending];
    }
    
    return decodedChat;
}


@end
