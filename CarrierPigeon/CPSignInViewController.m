//
//  CPSignInViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPSignInViewController.h"
#import "KeychainItemWrapper.h"

@interface CPSignInViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;


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
        KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"com.chrisdangelo.CarrierPigeon" accessGroup:nil];
        NSString *jid = [NSString stringWithFormat:@"%@@%@", self.usernameTextField, kXMPPServer];
        [[NSUserDefaults standardUserDefaults] setValue:jid forKey:kXMPPmyJID];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [keychain setObject:self.passwordTextField.text forKey:(__bridge id)kSecValueData];
        [self.delegate CPSignInViewControllerDidStoreCredentials:self];
    }
}

@end
