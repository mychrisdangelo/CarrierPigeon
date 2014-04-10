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

@interface CPSignInViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (nonatomic) BOOL isAlreadyConnected;

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
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:kUserHasConnectedPreviously];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Reorganize this code. should not assign own delegate!
        CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.delegate = delegate;
        self.xmppStream = delegate.xmppStream;
        [self.xmppStream disconnect];
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kPreviousUserConnectedWithPreferenceToUsePigeonsOnlyNotification];
}

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)xmppStreamDidAuthenticateHandler
{
    [self showContactsViewNow];
}

- (void)showContactsViewNow
{
    if (self.modalPresentationStyle == UIModalPresentationFormSheet) {
        [self.presenterDelegate CPSignInViewControllerDidSignIn:self];
    } else {
        [self performSegueWithIdentifier:@"ShowHomeTabBarController" sender:self];
    }
}

#pragma mark XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login"
                                                    message:@"Unable to sign in. Do you have an account?"
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
    
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

- (void)showAlertMissingUsernameOrPassword {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Required"
                                                    message:@"Username & Password required."
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
    return;
}

- (void)saveUserInfoAndBeginSignIn {
    
    KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kKeyChainItemWrapperPasswordIdentifer accessGroup:nil];
    NSString *jid = [NSString stringWithFormat:@"%@@%@", self.usernameTextField.text, kXMPPDomainName];
    [[NSUserDefaults standardUserDefaults] setValue:jid forKey:kXMPPmyJID];
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:kUserHasConnectedPreviously]; // will set YES on connect
    [[NSUserDefaults standardUserDefaults] synchronize];
    [keychain setObject:self.passwordTextField.text forKey:(__bridge id)kSecValueData];
    
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    [User addOrUpdateWithJidStr:jid withOnlyUsePigeonsSettings:NO forUpdate:NO inManagedObjectContext:delegate.managedObjectContext];
    
    [self.delegate CPSignInViewControllerDidStoreCredentials:self];
    
}

- (void) beginSignUp {
    
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.userWantsToRegister = YES;
    
    KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kKeyChainItemWrapperPasswordIdentifer accessGroup:nil];
    [keychain setObject:self.passwordTextField.text forKey:(__bridge id)kSecValueData];
    
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
            if (![self.xmppStream registerWithPassword:self.passwordTextField.text error:&error]) {
                DDLogError(@"Registration error: %@", error);
            }
            delegate.userWantsToRegister = NO;
        } else {
            DDLogError(@"Inband registration is not supported");
        }
    }
}


- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    // registration successful, disconnect stream to prevent unexpected authentication&connection errors
    [self.xmppStream disconnect];
    
    //begin sign in
    [self saveUserInfoAndBeginSignIn];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    [self.activityView stopAnimating];
    [self.signInButton setEnabled:YES];
    [self.signUpButton setEnabled:YES];
    
    //TODO: fix bug alert appears more than once on sign-in error
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sign Up Unsuccessful"
                                                    message:@"Unable to complete registration. Username may be taken."
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
    return;
}

@end
