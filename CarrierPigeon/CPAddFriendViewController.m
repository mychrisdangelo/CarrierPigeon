//
//  CPAddFriendViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPAddFriendViewController.h"

@interface CPAddFriendViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;

@end

@implementation CPAddFriendViewController

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

- (IBAction)addFriendButtonPressed:(UIButton *)sender {
    if ([self.usernameTextField.text isEqualToString:@""]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Username Required"
		                                                    message:@"Must enter a username to add a friend."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"OK"
		                                          otherButtonTitles:nil];
		[alertView show];
    } else {
        [self.delegate CPAddFriendViewControllerDidFinishAddingFriend:self withUserName:self.usernameTextField.text];
    }
}

- (IBAction)cancelButtonPressed:(UIButton *)sender {
    [self.delegate CPAddFriendViewControllerDidCancel:self];
}


@end
