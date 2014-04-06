//
//  User+AddOrUpdate.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "User+AddOrUpdate.h"

@implementation User (AddOrUpdate)

+ (User *)addOrUpdateWithJidStr:(NSString *)jidStr
     withOnlyUsePigeonsSettings:(BOOL)onlyUsePigeons
                      forUpdate:(BOOL)forUpdate
         inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"jidStr = %@", jidStr];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"jidStr" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        // sanity check
        NSLog(@"user exists twice");
    } else if ([matches count] == 0) {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
        user.jidStr = jidStr;
        user.onlyUsePigeons = @NO; // default
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"error saving");
        }
    } else {
        // only one object so update
        user = [matches lastObject];
        if (forUpdate) {
            user.onlyUsePigeons = [NSNumber numberWithBool:onlyUsePigeons];
        }
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"error saving");
        }
    }
    
    return user;
}

@end
