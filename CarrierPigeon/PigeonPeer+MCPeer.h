//
//  PigeonPeer+MCPeer.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

@import MultipeerConnectivity;
#import "PigeonPeer.h"

@interface PigeonPeer (MCPeer)

+ (PigeonPeer *)addPigeonPeerWithMCPeerID:(MCPeerID *)peerID inManagedObjectContext:(NSManagedObjectContext *)context;

@end
