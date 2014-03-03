//
//  Chat+Create.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat.h"
#import "XMPPUserCoreDataStorageObject.h"

@interface Chat (Create)

+ (Chat *)addChatWithXMPPMessage:(XMPPMessage *)message fromUser:(XMPPUserCoreDataStorageObject *)fromUser inManagedObjectContext:(NSManagedObjectContext *)context;

@end
