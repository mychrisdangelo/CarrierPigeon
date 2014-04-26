//
//  CPCreditsTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/26/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPCreditsTableViewController.h"
#import "CPCreditDetailViewController.h"

@interface CPCreditsTableViewController ()

@end

@implementation CPCreditsTableViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowCreditsDetail"]) {
        id vc = segue.destinationViewController;
        if ([vc isMemberOfClass:[CPCreditDetailViewController class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            CPCreditDetailViewController *cdvc = (CPCreditDetailViewController *)vc;
            cdvc.title = cell.textLabel.text;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ShowCreditsDetail" sender:cell];
}

@end
