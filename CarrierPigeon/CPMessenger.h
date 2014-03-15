//
//  CPMessenger.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/14/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPP.h"

@interface CPMessenger : NSObject

+(void)sendMessage:(NSString *)messageBody
              from:(NSString *)from
                to:(NSString *)to
        deviceUser:(NSString *)deviceUser
      onXMPPStream:(XMPPStream *)xmppStream
inManagedObjectContext:(NSManagedObjectContext *)context;

@end
