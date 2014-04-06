//
//  Contact.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/6/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Chat;

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSString * contactOwnerJidStr;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * jidStr;
@property (nonatomic, retain) id photo;
@property (nonatomic, retain) Chat *lastMessageAuthoredOrReceived;
@property (nonatomic, retain) NSSet *messagesReceived;
@property (nonatomic, retain) NSSet *messagesAuthored;
@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addMessagesReceivedObject:(Chat *)value;
- (void)removeMessagesReceivedObject:(Chat *)value;
- (void)addMessagesReceived:(NSSet *)values;
- (void)removeMessagesReceived:(NSSet *)values;

- (void)addMessagesAuthoredObject:(Chat *)value;
- (void)removeMessagesAuthoredObject:(Chat *)value;
- (void)addMessagesAuthored:(NSSet *)values;
- (void)removeMessagesAuthored:(NSSet *)values;

@end
