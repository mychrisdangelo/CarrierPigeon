//
//  CPSettingsViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/4/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPSettingsViewController.h"
#import "CPSignInViewController.h"

@interface CPSettingsViewController () <CPSignInViewControllerPresenterDelegate>

@end

@implementation CPSettingsViewController

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
    

    
    [self displayUserName];
}

- (void)displayUserName
{
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    NSArray *parsedJID = [myJID componentsSeparatedByString: @"@"];
    NSString *username = [parsedJID objectAtIndex:0];
    self.title = username;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowSignInSegue"]) {
        if ([segue.destinationViewController isMemberOfClass:[CPSignInViewController class]]) {
            CPSignInViewController *cpsivc = (CPSignInViewController *)segue.destinationViewController;
            cpsivc.userWantsToLogOut = YES;
            cpsivc.presenterDelegate = self;
        }
    }
}

#pragma mark - CPSignInViewControllerPresenterDelegate

- (void)CPSignInViewControllerDidSignIn:(CPSignInViewController *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tabBarController setSelectedIndex:0];
}

@end
