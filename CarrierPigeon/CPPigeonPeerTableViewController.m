//
//  CPPigeonPeerTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/5/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPPigeonPeerTableViewController.h"
#import "PigeonPeer.h"

@implementation CPPigeonPeerTableViewController

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

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.pigeonPeers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PigeonPeerCell" forIndexPath:indexPath];
    
    PigeonPeer *pigeon = self.pigeonPeers[indexPath.row];
    cell.textLabel.text = [CPHelperFunctions parseOutHostIfInDisplayName:pigeon.jidStr];
    
    return cell;
}

@end
