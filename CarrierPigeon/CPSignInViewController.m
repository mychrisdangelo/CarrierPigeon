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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
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

- (void)dealloc
{
    [self.xmppStream removeDelegate:self];
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
        sender.enabled = NO;
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
        [self saveUserInfoAndBeginSignIn];
        
        self.signUpButton.enabled = NO;
        self.signInButton.enabled = NO;
        [self.activityView startAnimating];
        
        [self.usernameTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
        
        NSError *err=nil;
        // check if inband registration is supported
        if (self.xmppStream.supportsInBandRegistration) {
            if (![self.xmppStream registerWithPassword:self.passwordTextField.text error:&err]) {
                DDLogError(@"Oops, I forgot something: %@", err);
            }
        } else {
            DDLogError(@"Inband registration is not supported");
        }
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
    //TODO: fix bug alert appears more than once on sign-in error
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
    [self.delegate CPSignInViewControllerDidStoreCredentials:self];
    
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self xmppStreamDidAuthenticateHandler];

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
