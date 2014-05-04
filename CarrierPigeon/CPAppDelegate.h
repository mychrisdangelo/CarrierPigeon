//
//  CarrierPigeonAppDelegate.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 2/26/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "XMPPvCardCoreDataStorage.h"
#import "CPSignInViewController.h"

extern NSString * const kXMPPStreamConnectionDidChangeNotification;
extern NSString * const kPreviousUserConnectedWithPreferenceToUsePigeonsOnlyNotification;
extern NSString * const kCurrentUserRecivingMessageInAConversationTheyAreNotViewingCurrentlyNotification;

@interface CPAppDelegate : UIResponder <UIApplicationDelegate, CPSignInViewControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) BOOL allowSelfSignedCertificates;
@property (nonatomic) BOOL allowSSLHostNameMismatch;
@property (nonatomic) BOOL isXmppConnected;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) NSString *conversationFromUserCurrentlyViewing;
@property (nonatomic) BOOL userWantsToRegister;
@property (nonatomic, strong) NSString *deviceTokenString;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;
- (BOOL)connect;
+ (BOOL)userHasLoggedInPreviously;

@end
