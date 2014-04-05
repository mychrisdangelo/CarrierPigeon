//
//  Chat+EncoderDecoder.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/4/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat.h"

@interface Chat (EncoderDecoder)

+ (Chat *)decodeDictionaryToChat:(NSDictionary *)chatDictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSDictionary *)encodeChatAsDictionary:(Chat *)chat;

@end
