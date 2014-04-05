//
//  CPNetworkStatus.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kNetworkStatusDidChangeNotification;

typedef NS_OPTIONS(NSUInteger, CPNetworkStatus) {
    CPNetworkStatusNoConnections = 0,
    CPNetworkStatusConnectedToXMPPStream = 1 << 0,
    CPNetworkStatusConnectedToPeerPigeons = 1 << 1,
};

@interface CPNetworkStatusAssistant : NSObject

+ (CPNetworkStatus)networkStatus;
+ (CPNetworkStatusAssistant *)sharedInstance;
+ (CPNetworkStatusAssistant *)start;
+ (UIColor *)colorForNetworkStatus;

@end
