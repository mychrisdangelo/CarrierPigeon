//
//  CPSessionEventLogTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/25/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPSessionEventLogTableViewController.h"
#import "CPSessionContainer.h"

@interface CPSessionEventLogTableViewController ()

@end

@implementation CPSessionEventLogTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.tableView reloadData];
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

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[CPSessionContainer sharedInstance] eventLog] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PigeonEventLogCell" forIndexPath:indexPath];
    
    NSDictionary *eventLogEntry = [[[CPSessionContainer sharedInstance] eventLog] objectAtIndex:indexPath.row];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", eventLogEntry[@"date"]];
    cell.textLabel.text = eventLogEntry[@"message"];
    
    return cell;
}

@end
