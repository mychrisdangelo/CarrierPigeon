//
//  CPSessionContainer.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//
//  Code Adapated from documenation provided by Apple (see above)



#import "CPSessionContainer.h"
#import "Chat.h"

@interface CPSessionContainer() <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic) MCNearbyServiceBrowser *serviceBrowser;
@property (nonatomic) MCSession *session;
@property (readwrite, nonatomic) NSMutableSet *currentPeers;

@end

@implementation CPSessionContainer

- (void)signInUserWithDisplayName:(NSString *)displayName
{
    MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    
    _session = [[MCSession alloc] initWithPeer:peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    _session.delegate = self;
    
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID discoveryInfo:nil serviceType:@"cp-chat"];
    [_serviceAdvertiser startAdvertisingPeer];
    _serviceAdvertiser.delegate = self;
    
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:@"cp-chat"];
    [_serviceBrowser startBrowsingForPeers];
    _serviceBrowser.delegate = self;
    
    _currentPeers = [[NSMutableSet alloc] init];
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
//    NSData *messageData = [chat dataUsingEncoding:NSUTF8StringEncoding];
//    // Send text message to all connected peers
//    NSError *error;
//    [self.session sendData:messageData toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
//    // Check the error return to know if there was an issue sending data to peers.  Note any peers in the 'toPeers' array argument are not connected this will fail.
//    if (error) {
//        NSLog(@"Error sending message to peers [%@]", error);
//        return nil;
//    }
//    else {
//        // Create a new send transcript
//        return [[Transcript alloc] initWithPeerID:_session.myPeerID message:message direction:TRANSCRIPT_DIRECTION_SEND];
//    }
}

#pragma mark - MCSessionDelegate methods

// Override this method to handle changes to peer session state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
//    NSLog(@"Peer [%@] changed state to %@", peerID.displayName, [self stringForPeerConnectionState:state]);
//
//    NSString *adminMessage = [NSString stringWithFormat:@"'%@' is %@", peerID.displayName, [self stringForPeerConnectionState:state]];
//    // Create an local transcript
//    Transcript *transcript = [[Transcript alloc] initWithPeerID:peerID message:adminMessage direction:TRANSCRIPT_DIRECTION_LOCAL];
//
//    // Notify the delegate that we have received a new chunk of data from a peer
//    [self.delegate receivedTranscript:transcript];
}

// MCSession Delegate callback when receiving data from a peer in a given session
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
//    // Decode the incoming data to a UTF8 encoded string
//    NSString *receivedMessage = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
//    // Create an received transcript
//    Transcript *transcript = [[Transcript alloc] initWithPeerID:peerID message:receivedMessage direction:TRANSCRIPT_DIRECTION_RECEIVE];
//    
//    // Notify the delegate that we have received a new chunk of data from a peer
//    [self.delegate receivedTranscript:transcript];
}

// MCSession delegate callback when we start to receive a resource from a peer in a given session
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
//    NSLog(@"Start receiving resource [%@] from peer %@ with progress [%@]", resourceName, peerID.displayName, progress);
//    // Create a resource progress transcript
//    Transcript *transcript = [[Transcript alloc] initWithPeerID:peerID imageName:resourceName progress:progress direction:TRANSCRIPT_DIRECTION_RECEIVE];
//    // Notify the UI delegate
//    [self.delegate receivedTranscript:transcript];
}

// MCSession delegate callback when a incoming resource transfer ends (possibly with error)
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
//    // If error is not nil something went wrong
//    if (error)
//    {
//        NSLog(@"Error [%@] receiving resource from peer %@ ", [error localizedDescription], peerID.displayName);
//    }
//    else
//    {
//        // No error so this is a completed transfer.  The resources is located in a temporary location and should be copied to a permenant locatation immediately.
//        // Write to documents directory
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *copyPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], resourceName];
//        if (![[NSFileManager defaultManager] copyItemAtPath:[localURL path] toPath:copyPath error:nil])
//        {
//            NSLog(@"Error copying resource to documents directory");
//        }
//        else {
//            // Get a URL for the path we just copied the resource to
//            NSURL *imageUrl = [NSURL fileURLWithPath:copyPath];
//            // Create an image transcript for this received image resource
//            Transcript *transcript = [[Transcript alloc] initWithPeerID:peerID imageUrl:imageUrl direction:TRANSCRIPT_DIRECTION_RECEIVE];
//            [self.delegate updateTranscript:transcript];
//        }
//    }
}

// Streaming API not utilized in this sample code
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
//    NSLog(@"Received data over stream with name %@ from peer %@", streamName, peerID.displayName);
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.currentPeers addObject:peerID];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.currentPeers removeObject:peerID];
}

@end
