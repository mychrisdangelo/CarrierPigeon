//
//  CPNearbyPigeonsTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/4/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPSessionContainer.h"
#import "CPNearbyPigeonsTableViewController.h"

@interface CPNearbyPigeonsTableViewController ()

@end

@implementation CPNearbyPigeonsTableViewController

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
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshPigeonListing:) forControlEvents:UIControlEventValueChanged];

}

- (void)refreshPigeonListing:(id)sender
{
    CPSessionContainer *sc = [CPSessionContainer sharedInstance];
    self.nearbyPigeons = [[sc peersInRange] allObjects];
    self.nearbyPigeonsConnected = [[sc peersInRangeConnected] copy];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.nearbyPigeons count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NearbyPigeonCell" forIndexPath:indexPath];
    
    MCPeerID *peerID = (MCPeerID *)self.nearbyPigeons[indexPath.row];
    cell.textLabel.text = [self parseOutHostIfInDisplayName:peerID.displayName];
    cell.detailTextLabel.text = [self.nearbyPigeonsConnected containsObject:peerID] ? @"Connected" : @"Unavailable";
    
    return cell;
}

- (NSString *)parseOutHostIfInDisplayName:(NSString *)displayName
{
    NSArray *parsedJID = [displayName componentsSeparatedByString: @"@"];
    NSString *username = [parsedJID objectAtIndex:0];
    return username;
}


@end
