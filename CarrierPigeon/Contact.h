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
@property (nonatomic, retain) NSSet *messageAuthored;
@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addMessageAuthoredObject:(Chat *)value;
- (void)removeMessageAuthoredObject:(Chat *)value;
- (void)addMessageAuthored:(NSSet *)values;
- (void)removeMessageAuthored:(NSSet *)values;

@end
