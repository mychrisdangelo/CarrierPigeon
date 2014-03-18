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
        self.userWantsToLogOut = NO;
        
        // Reorganize this code. should not assign own delegate!
        CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.delegate = delegate;
        self.xmppStream = delegate.xmppStream;
        [self.xmppStream disconnect];
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
}


- (IBAction)autoLoginButtonPressed:(UIButton *)sender {
    self.usernameTextField.text = @"chris";
    self.passwordTextField.text = @"uknowme";
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Required"
                                                        message:@"Username & Password required."
                                                       delegate:self cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    } else {
        KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kKeyChainItemWrapperPasswordIdentifer accessGroup:nil];
        NSString *jid = [NSString stringWithFormat:@"%@@%@", self.usernameTextField.text, kXMPPDomainName];
        [[NSUserDefaults standardUserDefaults] setValue:jid forKey:kXMPPmyJID];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:kUserHasConnectedPreviously]; // will set YES on connect
        [[NSUserDefaults standardUserDefaults] synchronize];
        [keychain setObject:self.passwordTextField.text forKey:(__bridge id)kSecValueData];
        [self.delegate CPSignInViewControllerDidStoreCredentials:self];
        
        sender.enabled = NO;
        [self.activityView startAnimating];
        [self.usernameTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
    }
}

- (IBAction)signUpButtonPressed:(UIButton *)sender {

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

#pragma mark XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    //    NSError *err=nil;
    //    // check if inband registration is supported
    //    if (self.xmppStream.supportsInBandRegistration)
    //    {
    //        if (![self.xmppStream registerWithPassword:self.passwordTextField.text error:&err])
    //        {
    //            DDLogError(@"Oops, I forgot something: %@", error);
    //        }
    //    }
    //    else
    //    {
    //        DDLogError(@"Inband registration is not supported");
    //    }
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login"
                                                    message:@"Sign in error occured."
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
    
    self.usernameTextField.text = @"";
    self.passwordTextField.text = @"";
    
    [self.signInButton setEnabled:YES];
    [self.activityView stopAnimating];
    [self.signInButton setEnabled:YES];
    [self.usernameTextField setHidden:NO];
    [self.passwordTextField setHidden:NO];
    [self.usernameTextField becomeFirstResponder];
    

}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    if (self.modalPresentationStyle == UIModalPresentationFormSheet) {
        [self.presenterDelegate CPSignInViewControllerDidSignIn:self];
    } else {
        [self performSegueWithIdentifier:@"ShowHomeTabBarController" sender:self];
    }

}


@end
