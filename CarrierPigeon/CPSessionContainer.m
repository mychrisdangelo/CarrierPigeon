//
//  CPSessionContainer.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//
//  Code Adapated from documenation provided by Apple (see above)

#import "CPSessionContainer.h"
#import "Chat+EncoderDecoder.h"
#import "Chat+Create.h"
#import "CPAppDelegate.h"
#import "CPMessenger.h"
#import "CPAppDelegate.h"
#import "PigeonPeer.h"

#define DEBUG_CPSESSION

NSString * const kPeerListChangedNotification = @"kPeerListChangedNotification";
@interface CPSessionContainer() <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic) MCNearbyServiceBrowser *serviceBrowser;
@property (nonatomic) MCSession *session;
@property (readwrite, nonatomic) NSMutableSet *peersInRange;
@property (readwrite, nonatomic) NSMutableSet *peersInRangeConnected;
@property (nonatomic) NSString *myDisplayName;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite) NSMutableArray *eventLog;

@end

@implementation CPSessionContainer

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = ((CPAppDelegate *)([[UIApplication sharedApplication] delegate])).managedObjectContext;
    }
    
    return _managedObjectContext;
}

- (void)signInUserWithDisplayName:(NSString *)displayName
{
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    self.myDisplayName = displayName;
    
    _session = [[MCSession alloc] initWithPeer:peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    _session.delegate = self;
    
    // for telling nearby peers I am available so you can invite me to a session
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID discoveryInfo:nil serviceType:@"cp-chat"];
    [_serviceAdvertiser startAdvertisingPeer];
    _serviceAdvertiser.delegate = self;
    
    // for looking for nearby peers to invite them to a session
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:@"cp-chat"];
    [_serviceBrowser startBrowsingForPeers];
    _serviceBrowser.delegate = self;
    
    _peersInRange = [[NSMutableSet alloc] init];
    _peersInRangeConnected = [[NSMutableSet alloc] init];
    
    self.eventLog = [[NSMutableArray alloc] init];
}

- (void)signOutUser
{
    CPSessionContainer *si = [CPSessionContainer sharedInstance];
    [si.serviceAdvertiser stopAdvertisingPeer];
    [si.serviceBrowser stopBrowsingForPeers];
    [si.session disconnect];
    self.eventLog = nil;
}

+ (id)sharedInstance
{
    static CPSessionContainer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc
{
    [self signOutUser];
}

- (NSString *)stringForPeerConnectionState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            return @"Connected";

        case MCSessionStateConnecting:
            return @"Connecting";

        case MCSessionStateNotConnected:
            return @"Not Connected";
    }
}

- (NSArray *)getPeersNotCurrentlyCarryingMessageAndOnlyGetPeersIfMessageShareLimitIsNotMaxed:(NSArray *)connectedPeers withChat:(Chat *)chat
{
    NSMutableArray *peersToSendTo = [[NSMutableArray alloc] init];
    NSMutableArray *previousCarriersOfThisMessageInStringArray = [[NSMutableArray alloc] init];
    int pigeonsCarryingMessageCount = (int)[chat.pigeonsCarryingMessage count];
    
    if (pigeonsCarryingMessageCount > kMaxCarrierPigeonsThatMayReceiveMessagePeerToPeer) {
        return nil;
    }
    
    for (PigeonPeer *eachPreviousCarrierOfThismessage in chat.pigeonsCarryingMessage) {
        [previousCarriersOfThisMessageInStringArray addObject:eachPreviousCarrierOfThismessage.jidStr];
    }
    
    for (MCPeerID *eachConnectedPeer in connectedPeers) {
        NSString *eachConnectedPeerDisplayName = eachConnectedPeer.displayName;
        if ([previousCarriersOfThisMessageInStringArray containsObject:eachConnectedPeerDisplayName]) {
            NSLog(@"Do Nothing. This user pigeon peer is already carrying our message.");
        } else if ([eachConnectedPeerDisplayName isEqualToString:self.myDisplayName]) {
            NSLog(@"Error: A connected peer has my display name");
        } else {
            if (pigeonsCarryingMessageCount++ < kMaxCarrierPigeonsThatMayReceiveMessagePeerToPeer) {
                [peersToSendTo addObject:eachConnectedPeer];
            } else {
                // we've found enough people to send to
                return peersToSendTo;
            }
        }
    }
    
    // we didn't max out there are people that haven't received our message
    return [peersToSendTo copy];
}

- (void)sendChat:(Chat *)chat
{
    NSDictionary *chatAsDictionary = [Chat encodeChatAsDictionary:chat];
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:chatAsDictionary];
    
    NSArray *peersToSendTo = [self getPeersNotCurrentlyCarryingMessageAndOnlyGetPeersIfMessageShareLimitIsNotMaxed:self.session.connectedPeers withChat:chat];
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    [Chat updateChat:chat withPigeonsCarryingMessage:peersToSendTo inManagedObjectContext:delegate.managedObjectContext];
    
    NSError *error;
    if ([peersToSendTo count]) {
        [self.session sendData:messageData toPeers:peersToSendTo withMode:MCSessionSendDataReliable error:&error];
    }
    if (error) {
        NSLog(@"Error: %@ %s", [error userInfo], __PRETTY_FUNCTION__);
    } else {
        
    }
}

#pragma mark - MCSessionDelegate methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSString *diagnosticMessage = [NSString stringWithFormat:@"%@ state: %@", peerID.displayName, [self stringForPeerConnectionState:state]];
    [self showNotificationOnDevice:diagnosticMessage];
    
    switch (state) {
        case MCSessionStateConnected:
            [self.peersInRangeConnected addObject:peerID.displayName];
            break;
        case MCSessionStateNotConnected:
            [self.peersInRangeConnected removeObject:peerID.displayName];
            break;
        case MCSessionStateConnecting:
        default:
            // not interested in this state
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeerListChangedNotification object:nil userInfo:nil];
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *chatAsDictionary = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    [Chat decodeDictionaryToChat:chatAsDictionary inManagedObjectContext:self.managedObjectContext asMessageRelayedByCurrentUser:self.myDisplayName];

    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    [CPMessenger sendPendingMessagesWithStream:delegate.xmppStream];
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    // nothing
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    // nothing
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    // nothing
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"Error: %@ %s", [error userInfo], __PRETTY_FUNCTION__);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    if (![self.session.connectedPeers containsObject:peerID]) {
        NSString *diagnosticMessage = [NSString stringWithFormat:@"accepting invitation from: %@", peerID.displayName];
        [self showNotificationOnDevice:diagnosticMessage];
        invitationHandler(YES, self.session);
    }

}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Error: %@ %s", [error userInfo], __PRETTY_FUNCTION__);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSString *diagnosticMessage = [NSString stringWithFormat:@"found peer: %@", peerID.displayName];
    [self showNotificationOnDevice:diagnosticMessage];
    
    if ([peerID.displayName isEqualToString:self.myDisplayName]) {
        NSLog(@"Error: I found someone with my own display name.");
        return;
    }
    
    if (![self.session.connectedPeers containsObject:peerID]) {
        NSString *diagnosticMessage = [NSString stringWithFormat:@"inviting peer: %@", peerID.displayName];
        [self showNotificationOnDevice:diagnosticMessage];
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:30.0];
    }
    
    [self.peersInRange addObject:peerID.displayName];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSString *diagnosticMessage = [NSString stringWithFormat:@"lost peer: %@", peerID.displayName];
    [self showNotificationOnDevice:diagnosticMessage];
    
    [self.peersInRange removeObject:peerID.displayName];
}

- (void)showNotificationOnDevice:(NSString *)message
{
#ifdef DEBUG_CPSESSION
    dispatch_async(dispatch_get_main_queue(), ^{
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CPSessionDiagnosticMessage"
//                                                            message:message
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//        [alertView show];
        
        [self.eventLog addObject:@{ @"date" : [NSDate date], @"message" : message }];
    });
#endif
}

@end
