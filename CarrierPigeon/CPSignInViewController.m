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
    
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
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
        NSString *jid = [NSString stringWithFormat:@"%@@%@", self.usernameTextField.text, kXMPPServer];
        [[NSUserDefaults standardUserDefaults] setValue:jid forKey:kXMPPmyJID];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [keychain setObject:self.passwordTextField.text forKey:(__bridge id)kSecValueData];
        [self.delegate CPSignInViewControllerDidStoreCredentials:self];
        
        sender.enabled = NO;
        [self.activityView startAnimating];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowHomeTabBarController"]) {
        if ([segue.destinationViewController isMemberOfClass:[UITabBarController class]]) {
            UITabBarController *tbc = (UITabBarController *)segue.destinationViewController;
            if ([tbc.viewControllers[0] isMemberOfClass:[UINavigationController class]]) {
                UINavigationController *navController = (UINavigationController *)tbc.viewControllers[0];
                if ([navController.viewControllers[0] isMemberOfClass:[CPContactsTableViewController class]]) {
                    CPContactsTableViewController *cpctvc = (CPContactsTableViewController *)navController.viewControllers[0];
                    cpctvc.xmppStream = self.xmppStream;
                }
            }
        }
        
//        if ([segue.destinationViewController isMemberOfClass:[CPContactsTableViewController class]]) {
//            CPContactsTableViewController *cpctvc = (CPContactsTableViewController *)segue.destinationViewController;
//            cpctvc.xmppStream = self.xmppStream;
//            
//            self.signInButton.enabled = YES;
//            [self.activityView stopAnimating];
//        }
    }
    
    self.signInButton.enabled = YES;
    [self.activityView stopAnimating];
}

#pragma mark XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSError *err=nil;
    // check if inband registration is supported
    if (self.xmppStream.supportsInBandRegistration)
    {
        if (![self.xmppStream registerWithPassword:self.passwordTextField.text error:&err])
        {
            DDLogError(@"Oops, I forgot something: %@", error);
        }
    }
    else
    {
        DDLogError(@"Inband registration is not supported");
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self performSegueWithIdentifier:@"ShowHomeTabBarController" sender:self];
}


@end
