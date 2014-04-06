//
//  User+AddOrUpdate.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "User.h"

@interface User (AddOrUpdate)

+ (User *)addOrUpdateWithJidStr:(NSString *)jidStr
     withOnlyUsePigeonsSettings:(BOOL)onlyUsePigeons
                      forUpdate:(BOOL)forUpdate
         inManagedObjectContext:(NSManagedObjectContext *)context;

@end
