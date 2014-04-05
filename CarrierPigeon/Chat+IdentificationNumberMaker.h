//
//  Chat+IdentificationNumberMaker.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "Chat.h"

@interface Chat (IdentificationNumberMaker)

+ (NSUInteger)generateNewIDNumberWithManagedObjectContext:(NSManagedObjectContext *)context withCurrentUser:(NSString *)currentUser;

@end
