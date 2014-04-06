//
//  CPNetworkStatusAssistant.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPNetworkStatusAssistant.h"
#import "XMPP.h"
#import "CPAppDelegate.h"
#import "CPSessionContainer.h"

NSString * const kNetworkStatusDidChangeNotification = @"kNetworkStatusDidChangeNotification";

@implementation CPNetworkStatusAssistant

+ (CPNetworkStatusAssistant *)start
{
    return [CPNetworkStatusAssistant sharedInstance];
}

+ (CPNetworkStatusAssistant *)sharedInstance
{
    static CPNetworkStatusAssistant *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(sendNetworkStatusChangeNotification) name:kXMPPStreamConnectionDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(sendNetworkStatusChangeNotification) name:kPeerListChangedNotification object:nil];
    });
    return sharedInstance;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kPeerListChangedNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kXMPPStreamConnectionDidChangeNotification];
}

- (void)sendNetworkStatusChangeNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkStatusDidChangeNotification object:nil userInfo:nil];
}

+ (CPNetworkStatus)networkStatus
{
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    XMPPStream *xmppStream = delegate.xmppStream;
    
    CPSessionContainer *sessionContainer = [CPSessionContainer sharedInstance];
    
    CPNetworkStatus networkStatus = CPNetworkStatusNoConnections;
    
    if ([xmppStream isConnected]) {
        networkStatus |= CPNetworkStatusConnectedToXMPPStream;
    }
    
    if ([sessionContainer.peersInRangeConnected count]) {
        networkStatus |= CPNetworkStatusConnectedToPeerPigeons;
    }
    
    return networkStatus;
}

+ (UIColor *)colorForNetworkStatusWithLightColor:(BOOL)lightColor
{
    CPNetworkStatus status = [CPNetworkStatusAssistant networkStatus];
    UIColor *networkStatusColor = lightColor ? kCarrierPigeonLightRedColor : kCarrierPigeonRedColor;
    
    if (status & CPNetworkStatusConnectedToXMPPStream) {
        networkStatusColor = lightColor ? kCarrierPigeonLightGreenColor : kCarrierPigeonGreenColor;
    } else if (status & CPNetworkStatusConnectedToPeerPigeons) {
        networkStatusColor = lightColor ? kCarrierPigeonLightYellowColor : kCarrierPigeonYellowColor;
    }
    
    return networkStatusColor;
}


@end
