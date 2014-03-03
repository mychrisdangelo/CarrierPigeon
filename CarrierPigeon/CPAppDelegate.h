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

@interface CPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) BOOL allowSelfSignedCertificates;
@property (nonatomic) BOOL allowSSLHostNameMismatch;
@property (nonatomic) BOOL isXmppConnected;

@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

@end
