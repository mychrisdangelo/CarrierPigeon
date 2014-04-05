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
#import "CPAppDelegate.h"

NSString * const kPeerListChangedNotification = @"kPeerListChangedNotification";

@interface CPSessionContainer() <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic) MCNearbyServiceBrowser *serviceBrowser;
@property (nonatomic) MCSession *session;
@property (readwrite, nonatomic) NSMutableSet *peersInRange;
@property (readwrite, nonatomic) NSMutableSet *peersInRangeConnected;
@property (nonatomic) NSString *myDisplayName;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;

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
}

- (void)signOutUser
{
    CPSessionContainer *si = [CPSessionContainer sharedInstance];
    [si.serviceAdvertiser stopAdvertisingPeer];
    [si.serviceBrowser stopBrowsingForPeers];
    [si.session disconnect];
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

// Helper method for human readable printing of MCSessionState.  This state is per peer.
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

#pragma mark - Public methods

//- (void)testEncoding:(Chat *)chat
//{
//    NSDictionary *dict = @{@"key" : @"value"};
//    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:dict];
//    [self testDecoding:messageData];
//}
//
//- (void)testDecoding:(NSData *)encodedChat
//{
//    NSDictionary *myDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:encodedChat];
//    NSLog(@"myDictionary = %@", myDictionary);
//}



- (void)sendChat:(Chat *)chat
{
    NSDictionary *chatAsDictionary = [Chat encodeChatAsDictionary:chat];
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:chatAsDictionary];
    
    NSError *error;
    [self.session sendData:messageData toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    // Check the error return to know if there was an issue sending data to peers.  Note any peers in the 'toPeers' array argument are not connected this will fail.
    if (error) {
        NSLog(@"Error sending message to peers [%@]", error);
    } else {
#warning handle message sent out success case
    }
}

#pragma mark - MCSessionDelegate methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            [self.peersInRangeConnected addObject:peerID];
            break;
        case MCSessionStateNotConnected:
        case MCSessionStateConnecting:
            [self.peersInRangeConnected removeObject:peerID];
            break;
    }
    
    NSLog(@"Me: %@ ... Peer [%@] changed state to %@", self.myDisplayName, peerID.displayName, [self stringForPeerConnectionState:state]);
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *chatAsDictionary = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    Chat *chat = [Chat decodeDictionaryToChat:chatAsDictionary inManagedObjectContext:self.managedObjectContext];
    NSLog(@"%@", chat);
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{

}

// Streaming API not utilized in this sample code
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{

}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"Me %@: %s", self.myDisplayName, __PRETTY_FUNCTION__);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{

    invitationHandler(YES, self.session);
    NSLog(@"Me %@ From %@: %s", self.myDisplayName, peerID.displayName, __PRETTY_FUNCTION__);
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
     NSLog(@"Me %@: %s", self.myDisplayName, __PRETTY_FUNCTION__);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    // don't recipricate invites. insight comes from: https://github.com/shrtlist/MCSessionP2P
    NSString *remotePeerName = peerID.displayName;
    MCPeerID *myPeerID = self.session.myPeerID;
    BOOL shouldInvite = ([myPeerID.displayName compare:remotePeerName] == NSOrderedDescending);
    if (shouldInvite) {
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:5.0];
    }
    
    [self.peersInRange addObject:peerID];
    NSLog(@"Me %@ foundPeer %@: %s", self.myDisplayName, peerID.displayName, __PRETTY_FUNCTION__);
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    [self.peersInRange removeObject:peerID];
    NSLog(@"Me %@: %s", self.myDisplayName, __PRETTY_FUNCTION__);
}

@end
