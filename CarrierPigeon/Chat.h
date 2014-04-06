//
//  Chat.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/6/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact, PigeonPeer;

@interface Chat : NSManagedObject

@property (nonatomic, retain) NSNumber * chatIDNumberPerOwner;
@property (nonatomic, retain) NSString * chatOwner;
@property (nonatomic, retain) NSString * filenameAsSent;
@property (nonatomic, retain) NSString * fromJID;
@property (nonatomic, retain) NSNumber * hasMedia;
@property (nonatomic, retain) NSNumber * isIncomingMessage;
@property (nonatomic, retain) NSNumber * isNew;
@property (nonatomic, retain) NSString * localFileName;
@property (nonatomic, retain) NSString * mediaType;
@property (nonatomic, retain) NSString * messageBody;
@property (nonatomic, retain) NSNumber * messageStatus;
@property (nonatomic, retain) NSString * mimeType;
@property (nonatomic, retain) NSString * reallyFromJID;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * toJID;
@property (nonatomic, retain) NSSet *pigeonsCarryingMessage;
@property (nonatomic, retain) Contact *authorOfMessage;
@end

@interface Chat (CoreDataGeneratedAccessors)

- (void)addPigeonsCarryingMessageObject:(PigeonPeer *)value;
- (void)removePigeonsCarryingMessageObject:(PigeonPeer *)value;
- (void)addPigeonsCarryingMessage:(NSSet *)values;
- (void)removePigeonsCarryingMessage:(NSSet *)values;

@end
