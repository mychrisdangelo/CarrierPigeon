//
//  Contact+AddRemove.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/14/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Contact.h"
#import "XMPPUserCoreDataStorageObject.h"

@interface Contact (AddRemove)

+ (Contact *)addRemoveContactFromXMPPUserCoreDataStorageObject:(XMPPUserCoreDataStorageObject *)xmppContact
                                                forCurrentUser:(NSString *)currentUser
                                        inManagedObjectContext:(NSManagedObjectContext *)context
                                                 removeContact:(BOOL)remove;

@end
