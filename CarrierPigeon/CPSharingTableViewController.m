//
//  CPSharingTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/17/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPSharingTableViewController.h"

@interface CPSharingTableViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *networkStatus;

@end

@implementation CPSharingTableViewController

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
    
    self.networkStatus.imageView.image = [UIImage imageNamed:@"GreenCircle"];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
