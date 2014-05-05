//
//  CPSignInViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPSignInViewController.h"
#import "KeychainItemWrapper.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "CPContactsTableViewController.h"
#import "CPAppDelegate.h"
#import "CPSessionContainer.h"
#import "User+AddOrUpdate.h"


// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define kAlertViewSignUpSuccess 11
#define kAlertViewSignUpFailure 12
#define kAlertViewSignInFailure 13
#define kAlertViewMissingUsernamePassword 14

@interface CPSignInViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (nonatomic) BOOL isAlreadyConnected;
@property (nonatomic) MPMoviePlayerController *moviePlayerController;

@end

@implementation CPSignInViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.xmppStream removeDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showContactsViewNow) name:kPreviousUserConnectedWithPreferenceToUsePigeonsOnlyNotification object:nil];
    
    if (self.autoLoginHasBegun) {
        [self.activityView startAnimating];
        [self.signInButton setEnabled:NO];
        [self.usernameTextField setHidden:YES];
        [self.passwordTextField setHidden:YES];
        self.autoLoginHasBegun = NO;
        
    }
    
    if (self.userWantsToLogOut) {
        [self.signInButton setEnabled:YES];
        [self.activityView stopAnimating];
        [self.signInButton setEnabled:YES];
        [self.usernameTextField setHidden:NO];
        [self.passwordTextField setHidden:NO];
        [self.usernameTextField becomeFirstResponder];
        [[CPSessionContainer sharedInstance] signOutUser];
        self.userWantsToLogOut = NO;
        
        [[NSUserDefaults standardUserDefaults] setValue:@NO forKey:kUserHasConnectedPreviously];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Reorganize this code. should not assign own delegate!
        CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.delegate = delegate;
        self.xmppStream = delegate.xmppStream;
        self.xmppRoster = delegate.xmppRoster;
        [self.xmppStream disconnect];
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        delegate.deviceTokenString = @"";
        BOOL isLogin = NO;
        [self updateAPNSTable: isLogin];
    }
    
    if ([CPAppDelegate userHasLoggedInPreviously]) {
        [self.presenterDelegate CPSignInViewControllerDidSignIn:self];
        return;
    }
    
    [self setupBackgroundVideo];
}

- (void)setupBackgroundVideo
{
    // video from http://www.beachfrontbroll.com/p/cities-and-traffic.html
    
    [self.moviePlayerController.view setAlpha:0.0];
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"traffic" ofType:@"m4v"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    self.moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:fileURL];
    
    self.moviePlayerController.repeatMode = MPMovieRepeatModeOne;
    self.moviePlayerController.controlStyle = MPMovieControlStyleNone;
    [self.moviePlayerController.view setFrame:self.view.bounds];
    self.moviePlayerController.scalingMode = MPMovieScalingModeAspectFill;
    [self.view addSubview:self.moviePlayerController.view];
    [self.view sendSubviewToBack:self.moviePlayerController.view];
    [self.moviePlayerController play];
    
    self.moviePlayerController.view.alpha = 0.0f;
    [UIView animateWithDuration:1.5 animations:^{
        self.moviePlayerController.view.alpha = 1.0f;
    }];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kPreviousUserConnectedWithPreferenceToUsePigeonsOnlyNotification];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IB Actions

- (IBAction)autoLoginButtonOnePressed:(UIButton *)sender {
    self.usernameTextField.text = @"CarrierPigeon1";
    self.passwordTextField.text = @"keyboardflub";
    [self signInButtonPressed:nil];
}

- (IBAction)autoLoginButtonTworessed:(UIButton *)sender {
    self.usernameTextField.text = @"CarrierPigeon2";
    self.passwordTextField.text = @"keyboardflub";
    [self signInButtonPressed:nil];
}

- (IBAction)autoLoginButtonThreePressed:(UIButton *)sender {
    self.usernameTextField.text = @"CarrierPigeon3";
    self.passwordTextField.text = @"keyboardflub";
    [self signInButtonPressed:nil];
}

- (IBAction)signInButtonPressed:(UIButton *)sender {
    
    if ([self.usernameTextField.text length] == 0 || [self.passwordTextField.text length] == 0) {
        [self showAlertMissingUsernameOrPassword];
    } else {
        [self.activityView startAnimating];
        self.signInButton.enabled = NO;
        self.signUpButton.enabled = NO;
        [self.usernameTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
        
        [self saveUserInfoAndBeginSignIn];
    }
}

- (IBAction)signUpButtonPressed:(UIButton *)sender {
    if ([self.usernameTextField.text length] == 0 || [self.passwordTextField.text length] == 0) {
        [self showAlertMissingUsernameOrPassword];
        
    } else {
        [self.activityView startAnimating];
        self.signUpButton.enabled = NO;
        self.signInButton.enabled = NO;
        
        [self.usernameTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
        
        [self beginSignUp];
    }
    
}

#pragma mark - Navigation

- (void)prepareContactsViewController:(NSArray *)viewControllers
{
    if ([viewControllers[0] isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *)viewControllers[0];
        if ([navController.viewControllers[0] isMemberOfClass:[CPContactsTableViewController class]]) {
            CPContactsTableViewController *cpctvc = (CPContactsTableViewController *)navController.viewControllers[0];
            cpctvc.xmppStream = self.xmppStream;
            cpctvc.xmppRoster = self.xmppRoster;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowHomeTabBarController"]) {
        if ([segue.destinationViewController isMemberOfClass:[UITabBarController class]]) {
            UITabBarController *tbc = (UITabBarController *)segue.destinationViewController;
            [self prepareContactsViewController:tbc.viewControllers];
        }
        if ([segue.destinationViewController isKindOfClass:[UISplitViewController class]]) {
            UISplitViewController *svc = (UISplitViewController *)segue.destinationViewController;
            if ([svc.viewControllers[0] isMemberOfClass:[UITabBarController class]]) {
                UITabBarController *tbc = (UITabBarController *)svc.viewControllers[0];
                [self prepareContactsViewController:tbc.viewControllers];
            }
        }
    }
    
    self.signInButton.enabled = YES;
    [self.activityView stopAnimating];
}

#pragma mark XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self showAlertSignInFailure];
    
    [self.signInButton setEnabled:YES];
    [self.signUpButton setEnabled:YES];
    [self.activityView stopAnimating];
    [self.usernameTextField setHidden:NO];
    [self.passwordTextField setHidden:NO];
    [self.usernameTextField becomeFirstResponder];
    
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self xmppStreamDidAuthenticateHandler];
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    // registration successful, disconnect stream to prevent unexpected authentication&connection errors
    [self.xmppStream disconnect];
    
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self showAlertSignUpSuccess];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    [self.activityView stopAnimating];
    [self.signInButton setEnabled:YES];
    [self.signUpButton setEnabled:YES];
    
    [self showAlertSignUpFailure];
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch (alertView.tag) {
        case kAlertViewSignUpSuccess:
            if (buttonIndex == 0) { //  Yes clicked, user wants to sign in now
                [self saveUserInfoAndBeginSignIn];
            } else if (buttonIndex == 1) { //  No clicked, user doesn't want to sign in now
                [self.activityView stopAnimating];
                [self.signInButton setEnabled:YES];
                [self.signUpButton setEnabled:YES];
            }
            break;
            
        case kAlertViewSignUpFailure:
            if (buttonIndex == 0) {
                return;
            }
            break;
            
        case kAlertViewSignInFailure:
            if (buttonIndex == 0) {
                return;
            }
            break;
            
        case kAlertViewMissingUsernamePassword:
            if (buttonIndex == 0) {
                return;
            }
            break;
    }
}

# pragma mark - Helper Functions

- (void)xmppStreamDidAuthenticateHandler
{
#if !TARGET_IPHONE_SIMULATOR
    BOOL isLogin = YES;
    [self updateAPNSTable: isLogin];
#endif
    [self showContactsViewNow];
}

- (void)showContactsViewNow
{
    [self.presenterDelegate CPSignInViewControllerDidSignIn:self];
}

- (void)saveUserInfoAndBeginSignIn {
    
    KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kKeyChainItemWrapperPasswordIdentifer accessGroup:nil];
    NSString *jid = [NSString stringWithFormat:@"%@@%@", self.usernameTextField.text, kXMPPDomainName];
    [[NSUserDefaults standardUserDefaults] setValue:jid forKey:kXMPPmyJID];
    [[NSUserDefaults standardUserDefaults] setValue:@NO forKey:kUserHasConnectedPreviously]; // will set YES on connect
    [[NSUserDefaults standardUserDefaults] synchronize];
    [keychain setObject:self.passwordTextField.text forKey:(__bridge id)kSecValueData];
    
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    [User addOrUpdateWithJidStr:jid withOnlyUsePigeonsSettings:NO forUpdate:NO inManagedObjectContext:delegate.managedObjectContext];
    
    [self.delegate CPSignInViewControllerDidStoreCredentials:self];
    
}

- (void)beginSignUp {
    
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.userWantsToRegister = YES;
    
    KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kKeyChainItemWrapperPasswordIdentifer accessGroup:nil];
    [keychain setObject:self.passwordTextField.text forKey:(__bridge id)kSecValueData];
    
    NSString *password = [keychain objectForKey:(__bridge id)kSecValueData];
    
    NSError *error = nil;
    NSString *jid = [NSString stringWithFormat:@"%@@%@", self.usernameTextField.text, kXMPPDomainName];
    
    [self.xmppStream setMyJID:[XMPPJID jidWithString:jid]];
    
    if([self.xmppStream isDisconnected]){
        // stream is not connected, attempt to connect
        if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
            DDLogError(@"Error connecting: %@", error);
        }
    } else {
        // check if inband registration is supported
        if (self.xmppStream.supportsInBandRegistration) {
            if (![self.xmppStream registerWithPassword:password error:&error]) {
                DDLogError(@"Registration error: %@", error);
            }
            delegate.userWantsToRegister = NO;
        } else {
            DDLogError(@"Inband registration is not supported");
        }
    }
}

- (void)showAlertMissingUsernameOrPassword {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Required"
                                                    message:@"Username & Password required."
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    alert.tag = kAlertViewMissingUsernamePassword;
    [alert show];
}


- (void)showAlertSignUpSuccess {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign Up Success"
                                                    message:@"Your account has been created. Do you want to sign in now?"
                                                   delegate:self cancelButtonTitle:@"Yes"
                                          otherButtonTitles:@"No", nil];
    alert.tag = kAlertViewSignUpSuccess;
    [alert show];
}

- (void)showAlertSignInFailure {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login"
                                                    message:@"Unable to sign in. Do you have an account?"
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    alert.tag = kAlertViewSignInFailure;
    [alert show];
}

- (void)showAlertSignUpFailure {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign Up Unsuccessful"
                                                    message:@"Unable to complete registration. Username may be taken."
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    alert.tag = kAlertViewSignUpFailure;
    [alert show];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //withdraw the keyboard when any area in the view outside the textfield is touched
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.usernameTextField isFirstResponder] && [touch view] != self.usernameTextField) {
        [self.usernameTextField resignFirstResponder];
    }
    
    if ([self.passwordTextField isFirstResponder] && [touch view] != self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void) updateAPNSTable: (BOOL) isLogin {
    
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSArray *myJIDArray = [[[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID] componentsSeparatedByString: @"@"];
    NSString *username = [myJIDArray objectAtIndex:0];
    
    // Check what notifications the user has turned on.
    NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    
    NSString *pushBadge = (rntypes & UIRemoteNotificationTypeBadge) ? @"enabled" : @"disabled";
    NSString *pushAlert = (rntypes & UIRemoteNotificationTypeAlert) ? @"enabled" : @"disabled";
    NSString *pushSound = (rntypes & UIRemoteNotificationTypeSound) ? @"enabled" : @"disabled";
    
    // Get the users Device Unique ID
    UIDevice *dev = [UIDevice currentDevice];
    NSString *deviceUid = nil;
    
    if ([dev respondsToSelector:@selector(identifierForVendor)])
        deviceUid = [[dev identifierForVendor] UUIDString];
    else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        id uuid = [defaults objectForKey:@"deviceUuid"];
        if (uuid)
            deviceUid = (NSString *)uuid;
        else {
            CFStringRef cfUuid = CFUUIDCreateString(NULL, CFUUIDCreate(NULL));
            deviceUid = (__bridge NSString *)cfUuid;
            CFRelease(cfUuid);
            [defaults setObject:deviceUid forKey:@"deviceUuid"];
        }
    }
    
    NSString *urlString = nil;
    NSString *updateReason = nil;
    
    if (isLogin) {
        // user just logged in, update the APNS table with the credentials of the device & user
        if (![delegate.deviceTokenString isEqualToString:@""]) {
            // this would only run the first time the user allows the "push notification" request from the app
            // associate the device token with the username
            updateReason = @"1"; // first update reason
            NSString *urlString = [NSString stringWithFormat:@"/apns.php?task=%@&devicetoken=%@&username=%@&updatereason=%@", @"update", delegate.deviceTokenString, username, updateReason];
            
            NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:kXMPPHostname path:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *urlR, NSData *returnData, NSError *e) {
                                     //  NSLog(@"Return Data for update reason 1: %@", returnData);
                                       
                                   }];
        } else {
            // the user may have already enabled push notifications for the app, update the database, just in case any of the notifications were disabled
            updateReason = @"2"; // second update reason
            urlString = [NSString stringWithFormat:@"/apns.php?task=%@&deviceuid=%@&pushbadge=%@&pushalert=%@&pushsound=%@&username=%@&updatereason=%@", @"update", deviceUid, pushBadge, pushAlert, pushSound, username, updateReason];
            
            NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:kXMPPHostname path:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *urlR, NSData *returnData, NSError *e) {
                                   //    NSLog(@"Return Data for update reason 2: %@", returnData);
                                       
                                   }];
        }
        
    } else {
        // user has logged out, update the APNS table and remove the username for the credentials of the device
        updateReason = @"3"; // third update reason
        urlString = [NSString stringWithFormat:@"/apns.php?task=%@&username=%@&updatereason=%@", @"update", username, updateReason];
        
        NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:kXMPPHostname path:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *urlR, NSData *returnData, NSError *e) {
                              //     NSLog(@"Return Data for update reason 3: %@", returnData);
                                   
                               }];
    }
    
}

@end
