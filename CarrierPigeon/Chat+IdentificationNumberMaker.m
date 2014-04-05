//
//  Chat+IdentificationNumberMaker.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat+IdentificationNumberMaker.h"

@implementation Chat (IdentificationNumberMaker)

+ (NSUInteger)generateNewIDNumberWithManagedObjectContext:(NSManagedObjectContext *)context withCurrentUser:(NSString *)currentUser
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Chat"];
    request.predicate = [NSPredicate predicateWithFormat:@"isIncomingMessage = %@ AND chatOwner = %@", @NO, currentUser];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    return [matches count] + 1;
}

@end
