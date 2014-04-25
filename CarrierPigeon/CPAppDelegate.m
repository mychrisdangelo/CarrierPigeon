// consider reorganizing assignments//
//  CarrierPigeonAppDelegate.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 2/26/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "KeychainItemWrapper.h"
#import "Chat+Create.h"
#import "XMPPMessageArchiving.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "CPContactsTableViewController.h"
#import "CPSessionContainer.h"
#import "CPNetworkStatusAssistant.h"
#import "XMPPMessageDeliveryReceipts.h"
#import "User+AddOrUpdate.h"
#import "TSMessage.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_ERROR;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

NSString * const kXMPPStreamConnectionDidChangeNotification = @"kXMPPStreamConnectionDidChangeNotification";
NSString * const kPreviousUserConnectedWithPreferenceToUsePigeonsOnlyNotification = @"kPreviousUserConnectedWithPreferenceToUsePigeonsOnlyNotification";
NSString * const kCurrentUserRecivingMessageInAConversationTheyAreNotViewingCurrentlyNotification = @"kCurrentUserRecivingMessageInAConversationTheyAreNotViewingCurrentlyNotification";

@interface CPAppDelegate()


@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) NSString *userPassword;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingStorage;
@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchive;
@property (nonatomic, strong) NSString * friendRequestFrom;

@end

@implementation CPAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [CPNetworkStatusAssistant start];
    
    // Configure logging framework
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    
    [self setupStream];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewcontroller = (UISplitViewController *)self.window.rootViewController;
        if ([splitViewcontroller.viewControllers[0] isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tabBarController = (UITabBarController *)splitViewcontroller.viewControllers[0];
            if ([tabBarController.viewControllers[0] isKindOfClass:[UINavigationController class]]) {
                UINavigationController *nc = (UINavigationController *)tabBarController.viewControllers[0];
                if ([nc.viewControllers[0] isMemberOfClass:[CPContactsTableViewController class]]) {
                    CPContactsTableViewController *controller = (CPContactsTableViewController *)nc.viewControllers[0];
                    controller.xmppStream = self.xmppStream;
                    controller.xmppRoster = self.xmppRoster;
                    if (![self userHasLoggedInPreviously]) {
                        controller.showPadSignInNow = YES;
                    } else {
                        controller.showPadSignInNow = NO;
                        [self connect];
                    }
                } else {
                    NSLog(@"Error: unexpected initial controller");
                }
            } else {
                NSLog(@"Error: unexpected initial controller");
            }
        } else {
            NSLog(@"Error: unexpected initial controller");
        }
    } else {
        UIStoryboard *storyboard;
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        if (![self userHasLoggedInPreviously]) {
            UINavigationController *nc = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"SignInNavigationControllerStoryboardID"];
            self.window.rootViewController = nc;
            
            if ([nc.viewControllers[0] isMemberOfClass:[CPSignInViewController class]]) {
                CPSignInViewController *sivc = (CPSignInViewController *)nc.viewControllers[0];
                sivc.delegate = self;
                sivc.xmppStream = self.xmppStream;
                sivc.xmppRoster = self.xmppRoster;
                [self.xmppStream addDelegate:sivc delegateQueue:dispatch_get_main_queue()];
            } else {
                NSLog(@"Error: unexpected initial controller");
            }
        } else {
            // we are in contacts view
            [self connect];
            UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
            if ([tabBarController.viewControllers[0] isKindOfClass:[UINavigationController class]]) {
                UINavigationController *nc = (UINavigationController *)tabBarController.viewControllers[0];
                if ([nc.viewControllers[0] isMemberOfClass:[CPContactsTableViewController class]]) {
                    CPContactsTableViewController *controller = (CPContactsTableViewController *)nc.viewControllers[0];
                    controller.xmppStream = self.xmppStream;
                    controller.xmppRoster = self.xmppRoster;
                } else {
                    NSLog(@"Error: unexpected initial controller");
                }
            } else {
                NSLog(@"Error: unexpected initial controller");
            }
        }
    }
    
    [[UITabBar appearance] setTintColor:kCarrierPigeonBlueColor];
    // [self testMessageArchiving];
    // [self testContactArchiving];
    
    [self setupTSMessageCustomDesign];
    
    // register for push notifications
#if !TARGET_IPHONE_SIMULATOR
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#endif

    return YES;
}

- (void)setupTSMessageCustomDesign
{
    [TSMessage addCustomDesignFromFileWithName:@"CustomBannerAlertDesign.json"];
}

- (BOOL)userHasLoggedInPreviously
{
    return [[[NSUserDefaults standardUserDefaults] stringForKey:kUserHasConnectedPreviously] boolValue];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)dealloc
{
	[self teardownStream];
}

- (BOOL)connect
{
    NSError *error = nil;
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    User *user = [User addOrUpdateWithJidStr:myJID withOnlyUsePigeonsSettings:NO forUpdate:NO inManagedObjectContext:self.managedObjectContext];
    if ([user.onlyUsePigeons boolValue]) {
        // user not interested in signing in only on connecting to peers
        [[CPSessionContainer sharedInstance] signInUserWithDisplayName:myJID];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviousUserConnectedWithPreferenceToUsePigeonsOnlyNotification object:nil userInfo:nil];
        return YES;
    }
    
    KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kKeyChainItemWrapperPasswordIdentifer accessGroup:nil];
 	NSString *myPassword = [keychain objectForKey:(__bridge id)kSecValueData];
    self.userPassword = myPassword;
    
	//
	// If you don't want to use the Settings view to set the JID,
	// uncomment the section below to hard code a JID and password.
	//
	// myJID = @"user@gmail.com/xmppframework";
	// myPassword = @"";
	
	if (myJID == nil || myPassword == nil) {
		return NO;
	}
    
	[self.xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    
    if (![self.xmppStream isDisconnected]) {
        // xmpp stream is already connected, try to authenticate with password if it is not authenticated
        if (!self.xmppStream.isAuthenticated) {
            if (![[self xmppStream] authenticateWithPassword:self.userPassword error:&error])
            {
                DDLogError(@"Error authenticating: %@", error);
            }
        }
        
		return YES;
	}
    
	if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
		                                                    message:@"See console for error details."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"OK"
		                                          otherButtonTitles:nil];
		[alertView show];
        
		DDLogError(@"Error connecting: %@", error);
        
		return NO;
	}
    
    [[CPSessionContainer sharedInstance] signInUserWithDisplayName:myJID];
    
	return YES;
}

- (void)setupStream
{
	NSAssert(self.xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	self.xmppStream = [[XMPPStream alloc] init];
    self.xmppStream.hostName = kXMPPHostname;
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		_xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	self.xmppReconnect = [[XMPPReconnect alloc] init];
    
    
    // Setup Archiving
    //
    self.xmppMessageArchivingStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    self.xmppMessageArchive = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:self.xmppMessageArchivingStorage];
    
    [self.xmppMessageArchive setClientSideMessageArchivingOnly:NO];
    
    [self.xmppMessageArchive activate:self.xmppStream];
    [self.xmppMessageArchive  addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // Setup Message Delivery Receipts
    //
    // TODO: Waiting on server side implementation of message receipts
    XMPPMessageDeliveryReceipts* xmppMessageDeliveryRecipts = [[XMPPMessageDeliveryReceipts alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    xmppMessageDeliveryRecipts.autoSendMessageDeliveryReceipts = YES;
    xmppMessageDeliveryRecipts.autoSendMessageDeliveryRequests = YES;
    [xmppMessageDeliveryRecipts activate:self.xmppStream];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
	
	self.xmppRoster.autoFetchRoster = YES;
	self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	self.xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppvCardStorage];
	
	self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTempModule];
	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
	self.xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    self.xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:self.xmppCapabilitiesStorage];
    
    self.xmppCapabilities.autoFetchHashedCapabilities = YES;
    self.xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
	// Activate xmpp modules
    
	[self.xmppReconnect         activate:self.xmppStream];
	[self.xmppRoster            activate:self.xmppStream];
	[self.xmppvCardTempModule   activate:self.xmppStream];
	[self.xmppvCardAvatarModule activate:self.xmppStream];
	[self.xmppCapabilities      activate:self.xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
	[self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];
	
    
	// You may need to alter these settings depending on the server you're connecting to
	self.allowSelfSignedCertificates = YES;
	self.allowSSLHostNameMismatch = NO;
}

- (void)teardownStream
{
	[self.xmppStream removeDelegate:self];
	[self.xmppRoster removeDelegate:self];
	
	[self.xmppReconnect         deactivate];
	[self.xmppRoster            deactivate];
	[self.xmppvCardTempModule   deactivate];
	[self.xmppvCardAvatarModule deactivate];
	[self.xmppCapabilities      deactivate];
	
	[self.xmppStream disconnect];
	
	self.xmppStream = nil;
	self.xmppReconnect = nil;
    self.xmppRoster = nil;
	self.xmppRosterStorage = nil;
	self.xmppvCardStorage = nil;
    self.xmppvCardTempModule = nil;
	self.xmppvCardAvatarModule = nil;
	self.xmppCapabilities = nil;
	self.xmppCapabilitiesStorage = nil;
}


- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    NSString *domain = [self.xmppStream.myJID domain];
    
    //Google set their presence priority to 24, so we do the same to be compatible.
    
    if([domain isEqualToString:@"gmail.com"]
       || [domain isEqualToString:@"gtalk.com"]
       || [domain isEqualToString:@"talk.google.com"])
    {
        NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
        [presence addChild:priority];
    }
	
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

#pragma mark - Core Data XMPP

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [self.xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
	return [self.xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CarrierPigeon" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CarrierPigeon.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - CPSignInViewControllerDelegate

- (void)CPSignInViewControllerDidStoreCredentials:(CPSignInViewController *)sender
{
    if (![self connect]) {
        DDLogInfo(@"%s: self connect failed", __PRETTY_FUNCTION__);
    }
}


#pragma mark - XMPPRosterDelegate

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[presence from]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self managedObjectContext_roster]];
    DDLogVerbose(@"didReceivePresenceSubscriptionRequest from user %@ ", user.jidStr);
    DDLogVerbose(@"didReceivePresenceSubscriptionRequest from user %@ ", [presence from]);
    
    NSString *atkXMPPDomainName = [@"@" stringByAppendingString:kXMPPDomainName];
    
    self.friendRequestFrom = [presence.fromStr stringByReplacingOccurrencesOfString: atkXMPPDomainName withString:@""];
    
    NSString *alertMessage = [NSString stringWithFormat:@"%@ would like to add you as a friend", self.friendRequestFrom];
    
    /* display an alert to let the user know of the new friend request */
    [self showFriendRequestAlertView:alertMessage];
}


#pragma mark - XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (self.allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (self.allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		NSString *expectedCertName = [self.xmppStream.myJID domain];
        
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	self.isXmppConnected = YES;
	
	NSError *error = nil;
	
    // check if the user wants to register
    if (self.userWantsToRegister) {
        
        KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kKeyChainItemWrapperPasswordIdentifer accessGroup:nil];
        self.userPassword = [keychain objectForKey:(__bridge id)kSecValueData];
        
        // check if inband registration is supported
        if (self.xmppStream.supportsInBandRegistration) {
            if (![self.xmppStream registerWithPassword:self.userPassword error:&error]) {
                DDLogError(@"Registration error: %@", error);
            }
            self.userWantsToRegister = NO;
        } else {
            DDLogError(@"Inband registration is not supported");
        }
    } else {
        if (![[self xmppStream] authenticateWithPassword:self.userPassword error:&error])
        {
            DDLogError(@"Error authenticating: %@", error);
        }
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kUserHasConnectedPreviously];
    [[NSUserDefaults standardUserDefaults] synchronize];
	
	[self goOnline];
    [[NSNotificationCenter defaultCenter] postNotificationName:kXMPPStreamConnectionDidChangeNotification object:nil userInfo:nil];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	if ([message isChatMessageWithBody])
	{
        XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[message from]
                                                                      xmppStream:self.xmppStream
                                                            managedObjectContext:[self managedObjectContext_roster]];
        
        NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
        [Chat addChatWithXMPPMessage:message fromUser:user.jidStr toUser:myJID deviceUser:myJID inManagedObjectContext:self.managedObjectContext withMessageStatus:CPChatSendStatusReceivedMessage withChatIDNumber:(-1)];
		
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];
        
		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            if (![self.conversationFromUserCurrentlyViewing isEqualToString:user.jidStr]) {
                NSString *parsedDisplayName = [CPHelperFunctions parseOutHostIfInDisplayName:displayName];
                [[NSNotificationCenter defaultCenter] postNotificationName:kCurrentUserRecivingMessageInAConversationTheyAreNotViewingCurrentlyNotification object:self userInfo:@{@"parsedDisplayName" : parsedDisplayName, @"body" : body}];
            }
		} else {
			/*
             * We are not active, so use a local notification instead. this will only work if we enable backgrounding. Xmppframework
             * gives this as an example where this will work with VOIP service enabled. However, applications will be rejected by
             * Apple if a service is enabled without just cause:
             * http://stackoverflow.com/questions/22756142/xmpp-chat-app-got-rejected-for-using-voip-service-as-background-mode
             */
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@", displayName, body];
            
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
	}
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!self.isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kXMPPStreamConnectionDidChangeNotification object:nil userInfo:nil];
}

#pragma mark - TestingMessageArchiving

// http://stackoverflow.com/questions/8568910/storing-messages-using-xmppframework-for-ios
-(void)printMessages:(NSMutableArray*)messages{
    @autoreleasepool {
        NSLog(@"**********************************");
        NSLog(@"** Print Archived Messages Test **");
        NSLog(@"**********************************");
        for (XMPPMessageArchiving_Message_CoreDataObject *message in messages) {
            NSLog(@"messageStr param is %@",message.messageStr);
            NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:message.messageStr error:nil];
            NSLog(@"to param is %@",[element attributeStringValueForName:@"to"]);
            NSLog(@"NSCore object id param is %@",message.objectID);
            NSLog(@"bareJid param is %@",message.bareJid);
            NSLog(@"bareJidStr param is %@",message.bareJidStr);
            NSLog(@"body param is %@",message.body);
            NSLog(@"timestamp param is %@",message.timestamp);
            NSLog(@"outgoing param is %d",[message.outgoing intValue]);
        }
        NSLog(@"**********************************");
    }
}

- (void)printContacts:(NSMutableArray*)contacts
{
    @autoreleasepool {
        NSLog(@"**********************************");
        NSLog(@"** Print Archived Contacts Test **");
        NSLog(@"**********************************");
        for (XMPPMessageArchiving_Contact_CoreDataObject *contact in contacts) {
            NSLog(@"bareJidstr %@", contact.bareJidStr);
            NSLog(@"mostRecentMessageBody %@", contact.mostRecentMessageBody);
        }
        NSLog(@"**********************************");
    }
}

- (void)testMessageArchiving
{
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Contact_CoreDataObject"
                                                         inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDescription];
    NSError *error;
    NSArray *messages = [moc executeFetchRequest:request error:&error];
    
    [self printContacts:[[NSMutableArray alloc]initWithArray:messages]];
}

- (void)testContactArchiving
{
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
                                                         inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDescription];
    NSError *error;
    NSArray *messages = [moc executeFetchRequest:request error:&error];
    
    [self printMessages:[[NSMutableArray alloc]initWithArray:messages]];
}


#pragma mark - Friend Request Helpers
- (void)showFriendRequestAlertView:(NSString*)alertMessage
{
    //TODO: add button "Not Now" to alert view
    //TODO: develop a friend request list that shows pending requests received only.
    // The pending requests would be removed from the list as they are accepted by the user.
    // I think this feature is needed to manage multiple requests coming to the user at the same time.
    // Please suggest a better approach for managing multiple friend request if this is inappropriate.
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Friend Request"
                                                        message:alertMessage
                                                       delegate:self
                                              cancelButtonTitle:@"Reject"
                                              otherButtonTitles:@"Accept", nil];
    
    [alertView show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSString *atkXMPPDomainName = [@"@" stringByAppendingString:kXMPPDomainName];
    
    self.friendRequestFrom = [self.friendRequestFrom stringByAppendingString:atkXMPPDomainName];
    
    if (buttonIndex == 0) {
        //Reject clicked
        if ([self.friendRequestFrom length] != 0) {
            [self.xmppRoster rejectPresenceSubscriptionRequestFrom:[XMPPJID jidWithString:self.friendRequestFrom]];
        }
    } else if (buttonIndex == 1) {
        //Accept clicked
        if ([self.friendRequestFrom length] != 0) {
            [self.xmppRoster acceptPresenceSubscriptionRequestFrom:[XMPPJID jidWithString:self.friendRequestFrom] andAddToRoster:YES];
        }
    }
}

# pragma mark - Push Notifications

-(void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // the phone token can be sent to the server using a http post request
    NSLog(@"Device token: %@", deviceToken);
}

-(void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Error registering for remote notification: %@", error);
}
@end
