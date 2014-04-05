//
//  PigeonPeer.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Chat;

@interface PigeonPeer : NSManagedObject

@property (nonatomic, retain) NSString * jidStr;
@property (nonatomic, retain) NSSet *messagesPigeonIsCarrying;
@end

@interface PigeonPeer (CoreDataGeneratedAccessors)

- (void)addMessagesPigeonIsCarryingObject:(Chat *)value;
- (void)removeMessagesPigeonIsCarryingObject:(Chat *)value;
- (void)addMessagesPigeonIsCarrying:(NSSet *)values;
- (void)removeMessagesPigeonIsCarrying:(NSSet *)values;

@end
