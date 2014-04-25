//
//  Contact+AddRemove.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/14/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Contact+AddRemove.h"

@implementation Contact (AddRemove)

+ (Contact *)addRemoveContactFromXMPPUserCoreDataStorageObject:(XMPPUserCoreDataStorageObject *)xmppContact
                                                forCurrentUser:(NSString *)currentUser
                                        inManagedObjectContext:(NSManagedObjectContext *)context
                                                 removeContact:(BOOL)remove
{
    Contact *contact;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    request.predicate = [NSPredicate predicateWithFormat:@"jidStr = %@ AND contactOwnerJidStr = %@", xmppContact.jidStr, currentUser];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"jidStr" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        // sanity check
        NSLog(@"contact exists more than once");
    } else if ([matches count] == 0) {
        //TODO: only add to contacts when subscription=both
        contact = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:context];
        contact.jidStr = xmppContact.jidStr;
        contact.displayName = xmppContact.displayName;
        contact.photo = xmppContact.photo;
        contact.contactOwnerJidStr = currentUser;
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"error saving");
        }
    } else {
        // only one object
        contact = [matches lastObject];
        
        if (remove) {
            [context deleteObject:contact];
            
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"error saving");
            }
        }
    }
    
    return contact;
}

@end
