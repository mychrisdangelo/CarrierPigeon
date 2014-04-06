//
//  CPEditProfileTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/6/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPEditProfileTableViewController.h"

@interface CPEditProfileTableViewController ()

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
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


@end
