//
//  PigeonPeer+MCPeer.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "PigeonPeer+MCPeer.h"

@implementation PigeonPeer (MCPeer)

+ (PigeonPeer *)addPigeonPeerWithMCPeerID:(MCPeerID *)peerID inManagedObjectContext:(NSManagedObjectContext *)context
{
    PigeonPeer *pigeon;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PigeonPeer"];
    request.predicate = [NSPredicate predicateWithFormat:@"jidStr = %@", peerID.displayName];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"jidStr" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        // sanity check
        NSLog(@"pigeon peer exists twice");
    } else if ([matches count] == 0) {
        pigeon = [NSEntityDescription insertNewObjectForEntityForName:@"PigeonPeer" inManagedObjectContext:context];
        pigeon.jidStr = peerID.displayName;
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"error saving");
        }
    } else {
        // only one object
        pigeon = [matches lastObject];
    }
    
    return pigeon;
}

@end
