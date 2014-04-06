//
//  CPHelperFunctions.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPHelperFunctions.h"

@implementation CPHelperFunctions

+ (NSString *)parseOutHostIfInDisplayName:(NSString *)displayName
{
    NSArray *parsedJID = [displayName componentsSeparatedByString: @"@"];
    NSString *username = [parsedJID objectAtIndex:0];
    return username;
}

@end
