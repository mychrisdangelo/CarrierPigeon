//
//  CPEditProfileTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/6/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPEditProfileTableViewController.h"
#import "CPAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "KeychainItemWrapper.h"


#define kAlertViewChangePasswordFailure 21
#define kAlertViewChangePasswordSuccess 22
#define kAlertViewBothPasswordsRequired 23
#define kAlertViewBothPasswordsMustMatch 24

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface CPEditProfileTableViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *changeProfileImageCell;
@property (weak, nonatomic) IBOutlet UITextField *passwordFirst;
@property (weak, nonatomic) IBOutlet UITextField *passwordSecond;

@end

@implementation CPEditProfileTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.passwordFirst.delegate = self;
    self.passwordSecond.delegate = self;
    
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.xmppStream = delegate.xmppStream;
    self.xmppRoster = delegate.xmppRoster;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    NSError *error = nil;
    
    if (textField == self.passwordFirst) {
        [self.passwordSecond becomeFirstResponder];
        return NO;
    } else if (textField == self.passwordSecond) {
        [self.passwordSecond resignFirstResponder];
        
        if ([self.passwordFirst.text length] == 0 || [self.passwordSecond.text length] == 0) {
            [self showAlertBothPasswordsRequired];
        } else {
            if ([self compare:self.passwordFirst.text with:self.passwordSecond.text]){
                if([self.xmppStream isDisconnected]){
                    // stream is not connected
                    NSLog(@"XMPP Stream is disconnected");
                    [self showAlertChangePasswordFailure];
                } else {
                    [self doChangePassword];
                }
            } else {
                [self showAlertBothPasswordsMustMatch];
            }
        }
    }
    return YES;
}

#pragma mark XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, error);
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, error);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error {
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, error);
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch (alertView.tag) {
        case kAlertViewChangePasswordSuccess:
            if (buttonIndex == 0) {
                return;
            }
            break;
            
        case kAlertViewChangePasswordFailure:
            if (buttonIndex == 0) {
                return;
            }
            break;
            
        case kAlertViewBothPasswordsRequired:
            if (buttonIndex == 0) {
                return;
            }
            break;
            
        case kAlertViewBothPasswordsMustMatch:
            if (buttonIndex == 0) {
                return;
            }
            break;
    }
}

# pragma mark - Helper Functions

-(BOOL) compare: (NSString*) firstPassword with: (NSString*) secondPassword {
    // returns YES if both passwords match
    return [firstPassword isEqualToString:secondPassword] ? YES : NO;
}

-(void) showAlertChangePasswordFailure {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password not changed"
                                                    message:@"Unable to change password now. Please try again later"
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    alert.tag = kAlertViewChangePasswordFailure;
    [alert show];
    return;
}

-(void) showAlertChangePasswordSuccess {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                    message:@"Password successfully changed."
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    //TODO: you could give the user an opportunity to sign out here
    alert.tag = kAlertViewChangePasswordSuccess;
    [alert show];
    return;
}

-(void) showAlertBothPasswordsRequired {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Required"
                                                    message:@"Both passwords are required."
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    alert.tag = kAlertViewBothPasswordsRequired;
    [alert show];
    return;
}

-(void) showAlertBothPasswordsMustMatch {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Mismatch"
                                                    message:@"Both passwords don't match."
                                                   delegate:self cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    alert.tag = kAlertViewBothPasswordsMustMatch;
    [alert show];
    return;
}

-(void) doChangePassword {
    NSError* error = nil;
    
    // check if inband registration is supported
    if (self.xmppStream.supportsInBandRegistration) {
        if (![self.xmppStream registerWithPassword:self.passwordFirst.text error:&error]) {
            DDLogError(@"Registration error: %@", error);
            [self showAlertChangePasswordFailure];
        } else {
            self.passwordFirst.text = @"";
            self.passwordSecond.text = @"";
            [self showAlertChangePasswordSuccess];
        }
    } else {
        [self showAlertChangePasswordFailure];
        DDLogError(@"Inband registration is not supported");
    }
}

@end
