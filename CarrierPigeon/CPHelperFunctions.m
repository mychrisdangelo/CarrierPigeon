//
//  CPHelperFunctions.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPHelperFunctions.h"
#import "NSDate-Utilities.h"

@implementation CPHelperFunctions

+(NSString *)dayLabelForMessage:(NSDate *)msgDate
{
    NSString *retStr = @"";
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *time = [formatter stringFromDate:msgDate];
    
    if ([msgDate isToday])
    {
        retStr = [NSString stringWithFormat:@"today %@",time];
    }
    else if ([msgDate isYesterday])
    {
        retStr = [NSString stringWithFormat:@"yesterday %@" ,time];
    }
    else
    {
        [formatter setDateFormat:@"yyyy/MM/dd HH:mm"];
        NSString *time = [formatter stringFromDate:msgDate];
        retStr = [NSString stringWithFormat:@"%@" ,time];
    }
    return retStr;
}

+ (NSString *)parseOutHostIfInDisplayName:(NSString *)displayName
{
    NSArray *parsedJID = [displayName componentsSeparatedByString: @"@"];
    NSString *username = [parsedJID objectAtIndex:0];
    return username;
}

@end
