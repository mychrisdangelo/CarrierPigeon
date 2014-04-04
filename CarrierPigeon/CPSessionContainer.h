//
//  CPSessionContainer.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//
//  Code Adapated from documenation provided by Apple (see above)

@import MultipeerConnectivity;
#import <Foundation/Foundation.h>

extern NSString * const kPeerListChangedNotification;

@class Chat;

@protocol SessionContainerDelegate;

@interface CPSessionContainer : NSObject

+ (instancetype)sharedInstance;
- (void)sendChat:(Chat *)chat;
@property (readonly, nonatomic) NSMutableSet *currentPeers;
- (void)signInUserWithDisplayName:(NSString *)displayName;
- (void)signOutUser;

//- (void)testEncoding:(Chat *)chat;
//- (void)testDecoding:(NSData *)encodedChat;

@end