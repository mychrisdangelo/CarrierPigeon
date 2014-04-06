//
//  CPSettingsViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/4/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPSettingsViewController.h"
#import "CPSignInViewController.h"
#import "CPAppDelegate.h"
#import "User+AddOrUpdate.h"

@interface CPSettingsViewController () <CPSignInViewControllerPresenterDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *onlyUsePigeonsSwitch;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSString *myJID;

@end

@implementation CPSettingsViewController

- (NSString *)myJID
{
    if (_myJID == nil) {
        _myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    }
    
    return _myJID;
}

- (NSManagedObjectContext *)context
{
    if (_context == nil) {
        CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
        _context = [delegate managedObjectContext];
    }
    
    return _context;
}

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

    User *user = [User addOrUpdateWithJidStr:self.myJID withOnlyUsePigeonsSettings:NO forUpdate:NO inManagedObjectContext:self.context];
    [self.onlyUsePigeonsSwitch setOn:[user.onlyUsePigeons boolValue]];
    
    [self refreshUserNameInTitle];
}

- (void)refreshUserNameInTitle
{
    self.title = [CPHelperFunctions parseOutHostIfInDisplayName:self.myJID];
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

- (IBAction)onlyUsePigeonsSwitchDidChange:(UISwitch *)sender
{

    [User addOrUpdateWithJidStr:self.myJID withOnlyUsePigeonsSettings:sender.on forUpdate:YES inManagedObjectContext:self.context];
}

#pragma mark - CPSignInViewControllerPresenterDelegate

- (void)CPSignInViewControllerDidSignIn:(CPSignInViewController *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tabBarController setSelectedIndex:0];
    
    [self refreshUserNameInTitle];
}

@end
