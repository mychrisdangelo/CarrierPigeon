//
//  Chat.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/25/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat.h"
#import "Contact.h"
#import "PigeonPeer.h"


@implementation Chat

@dynamic chatIDNumberPerOwner;
@dynamic chatOwner;
@dynamic filenameAsSent;
@dynamic fromJID;
@dynamic hasMedia;
@dynamic isIncomingMessage;
@dynamic isNew;
@dynamic localFileName;
@dynamic mediaType;
@dynamic messageBody;
@dynamic messageStatus;
@dynamic mimeType;
@dynamic reallyFromJID;
@dynamic receiverReadTimestamp;
@dynamic receiverReceivedTimestamp;
@dynamic senderSentTimestamp;
@dynamic serverReceivedTimestamp;
@dynamic timeStamp;
@dynamic toJID;
@dynamic reallyFromChatIDNumber;
@dynamic authorOfMessage;
@dynamic lastAuthorOrRecipient;
@dynamic pigeonsCarryingMessage;
@dynamic recipientOfMessage;

@end
