//
//  Contact.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/14/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Contact : NSManagedObject

@property (nonatomic, retain) NSString * jidStr;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) id photo;
@property (nonatomic, retain) NSString * contactOwnerJidStr;

@end
